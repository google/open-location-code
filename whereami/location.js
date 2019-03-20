/**
 * @fileoverview Requests location from the browser, and displays the
 * global plus code. If the request included a parameter "key", that will be
 * used to request a plus code address (short code and locality).
 */

// By default we will try to get a high accuracy location. If that fails, we
// will try again with low accuracy.
var locationOptions = {
  enableHighAccuracy: true,
  maximumAge: 30000,
  timeout: 27000
};

// Convert a latitude and longitude into a 10 digit plus code.
function createPluscode(lat, lng) {
  var a = (lat + 90) * 1e6, b = (lng + 180) * 1e6, c = '';
  for (var i = 0; i < 10; i++) {
    c = '23456789CFGHJMPQRVWX'.charAt(b / 125 % 20) + c;
    b = [a, a = b / 20][0];
  }
  return c.substring(0, 8) + '+' + c.substring(8);
}

// Make a request to the Google Geocoding API to convert the lat/lng into
// a plus code and locality.
function geocode(lat, lng) {
  // Get the key parameter from the web page, if there isn't one, skip making
  // the request.
  var wp = new URL(window.location);
  var key = wp.searchParams.get('key');
  if (key == null) {
    return;
  }
  var xmlhttp = new XMLHttpRequest();
  var url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' + lat +
      ',' + lng + '&key=' + key;

  xmlhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      // Request is finished an successful. If it includes a compound code,
      // it can be displayed.
      var response = JSON.parse(this.responseText);
      if (typeof response.plus_code != 'undefined' &&
          typeof response.plus_code.compound_code != 'undefined') {
        document.getElementById('code_locality').textContent =
            response.plus_code.compound_code;
        // Show the compound code and hide the global code.
        document.getElementById('code_locality').classList.remove('hide');
        document.getElementById('code_only').classList.add('hide');
      }
    }
  };
  xmlhttp.open('GET', url, true);
  xmlhttp.send();
}

// Turn a location into a plus code and display it.
function receivePosition(position) {
  var pc = createPluscode(position.coords.latitude, position.coords.longitude);
  document.getElementById('area_code').textContent = pc.substring(0, 4);
  document.getElementById('local_code').textContent = pc.substring(4);
  // Hide the fetching message and display the location section.
  document.getElementById('fetching').classList.add('hide');
  document.getElementById('location').classList.remove('hide');
  if (typeof position.coords.accuracy != 'undefined') {
    document.getElementById('accuracy_meters').textContent =
        Math.round(position.coords.accuracy);
    // Show the accuracy message.
    document.getElementById('accuracy_not_available').classList.add('hide');
    document.getElementById('accuracy').classList.remove('hide');
  }
  geocode(position.coords.latitude, position.coords.longitude);
}

function positionError(err) {
  if (positionError.code == 3) {
    // 3 is timeout, so reduce the accuracy and try again.
    locationOptions.enableHighAccuracy = false;
    getLocation();
  } else {
    // Probably permission denied or some error.
    document.getElementById('fetching').classList.add('hide');
    document.getElementById('permission_error').classList.remove('hide');
  }
}

// Request the device location, and display it to the user as a plus code.
function getLocation() {
  // Check if we are loaded over https. If not, show a message.
  if (window.location.protocol != 'https:') {
    var url = new URL(window.location);
    url.protocol = 'https:';
    document.getElementById('https_retry').href = url.href;
    document.getElementById('fetching').classList.add('hide');
    document.getElementById('not_https_error').classList.remove('hide');
    return;
  }
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
        receivePosition, positionError, locationOptions);
  } else {
    document.getElementById('fetching').classList.add('hide');
    document.getElementById('not_supported').classList.remove('hide');
  }
}
