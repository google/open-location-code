# <https://plus.codes> API Developer's Guide

### Table of Contents
- [https://plus.codes API Developer's Guide](#httpspluscodes-api-developers-guide)
    - [Table of Contents](#table-of-contents)
  - [History](#history)
  - [Functionality](#functionality)
  - [API Request Format](#api-request-format)
  - [Example Requests (no Google API key)](#example-requests-no-google-api-key)
  - [Example Requests (with Google API key)](#example-requests-with-google-api-key)
  - [JSON Response Format](#json-response-format)
    - [Locality Requests](#locality-requests)
  - [API Keys](#api-keys)
    - [Obtaining A Google API Key](#obtaining-a-google-api-key)
    - [Securing Your API Key](#securing-your-api-key)
    - [Securing Your API Key With An HTTP Referrer](#securing-your-api-key-with-an-http-referrer)
      - [Allowing Multiple Referrers](#allowing-multiple-referrers)

> This API is *experimental*.
As of December 2016, we are soliciting feedback on the functionality, in order to inform proposals to geocoding API providers such as Google.
You can discuss the API in the [public mailing list](https://groups.google.com/forum/#!forum/open-location-code) or create an issue in the [issue tracker](https://github.com/google/open-location-code/issues/new?labels=api&assignee=drinckes).

> If the API needs to be turned off, or there are other important messages, they will be returned in the JSON result in the field `error_message`, described on this page, or sent to the [mailing list](https://groups.google.com/forum/#!forum/open-location-code).

> Feb/March 2017: Google API keys are required for the generation of short codes and searching by address.
See the [API Keys](#api-keys) section and the `key` parameter.

> October 2018: v2 of the API is launched that returns the same localities that are displayed in Google Maps.
A side effect of this update is that the API should be slightly faster, and if API keys are used, the cost should be reduced.

## History

*  December 2016. v1 of API launched
*  October 2018. v2 of API launched and made default.

## Functionality

The API provides the following functions:

*  Conversion of a latitude and longitude to a Plus Code (including the bounding box and the center);
*  Conversion of a Plus Code to the bounding box and center.

Additionally, it can use the [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro) to:

*  Include short codes and localities in the returned Plus Code (such as "WF8Q+WF Praia, Cape Verde" for "796RWF8Q+WF");
*  Handle converting from a street address or business name to the Plus Code;
*  Handle converting a short code and locality to the global code and coordinates.

The results are provided in JSON format.
The API is loosely modeled on the [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro).

## API Request Format

A Plus Codes API request takes the following form:

`https://plus.codes/api?parameters`

**Note**: URLs must be [properly encoded](https://developers.google.com/maps/web-services/overview#BuildingURLs) (specifically, `+` characters must be encoded to `%2B`).

**Required parameter:**

* `address` — The address to encode.
  This can be any of the following (if the `ekey` parameter is also provided):
  * A latitude/longitude
  * A street address
  * A global code
  * A local code and locality
  * ~~A local code and latitude/longitude~~ (Deprecated in v2 of the API)

**Recommended parameters:**

* `key` — An Google API key.
  See [API Keys](#api-keys).
  If this parameter is omitted, only latitude/longitude and global codes can be used in the `address` parameter, and locality information will not be returned. (This can also be specified using `ekey`.)
* `email` — Provide an email address that can be used to contact you.
* `language` — The language in which to return results.
  This won't affect the global code, but it will affect the names of any features generated, as well as the address used for the local code.
 * If `language` is not supplied, results will be provided in English.

## Example Requests (no Google API key)

The following two requests show how to convert a latitude and longitude to a code, or how to get the geometry of a global code:

*  https://plus.codes/api?address=14.917313,-23.511313&email=YOUR_EMAIL_HERE
*  https://plus.codes/api?address=796RWF8Q%2BWF&email=YOUR_EMAIL_HERE

Both of these requests will return the global code, it's geometry, and the center:

```javascript
{
  "plus_code": {
    "global_code": "796RWF8Q+WF",
    "geometry": {
      "bounds": {
        "northeast": {
          "lat": 14.917375000000007,
          "lng": -23.511250000000018
        },
        "southwest": {
          "lat": 14.91725000000001,
          "lng": -23.511375000000015
        }
      },
      "location": {
        "lat": 14.917312500000008,
        "lng": -23.511312500000017
      }
    },
  },
  "status": "OK"
}
```

## Example Requests (with Google API key)

Here are some example requests.
You must include your Google API key in the request for these to work fully:

*  https://plus.codes/api?address=14.917313,-23.511313&ekey=YOUR_ENCRYPTED_KEY&email=YOUR_EMAIL_HERE
*  https://plus.codes/api?address=796RWF8Q%2BWF&ekey=YOUR_ENCRYPTED_KEY&email=YOUR_EMAIL_HERE
*  https://plus.codes/api?address=WF8Q%2BWF%20Praia%20Cape%20Verde&ekey=YOUR_ENCRYPTED_KEY&email=YOUR_EMAIL_HERE

These requests would all return:

```javascript

  "plus_code": {
    "global_code": "796RWF8Q+WF",
    "geometry": {
      "bounds": {
        "northeast": {
          "lat": 14.917375000000007,
          "lng": -23.511250000000018
        },
        "southwest": {
          "lat": 14.91725000000001,
          "lng": -23.511375000000015
        }
      },
      "location": {
        "lat": 14.917312500000008,
        "lng": -23.511312500000017
      }
    },
    "local_code": "WF8Q+WF",
    "locality": {
      "local_address": "Praia, Cape Verde"
    },
  },
  "status": "OK"
}
```

## JSON Response Format

The JSON response contains two root elements:

*  `"status"` contains metadata on the request.
   Other status values are documented [here](https://developers.google.com/maps/documentation/geocoding/intro#StatusCodes).
*  `"plus_code"` contains the Plus Code information for the location specified in `address`.

> There may be an additional `error_message` field within the response object.
> This may contain additional background information for the status code.

The `plus_code` structure has the following fields:
*  `global_code` gives the global code for the latitude/longitude
*  `bounds` provides the bounding box of the code, with the north east and south west coordinates
*  `location` provides the centre of the bounding box.

If a locality feature near enough and large enough to be used to shorten the code was found, the following fields will also be returned:
*  `local_code` gives the local code relative to the locality
*  `locality` provides the name of the locality using `local_address`.

If the `ekey` encrypted key is not provided the following fields will not be returned:
*  `local_code`
*  `locality`
*  `local_address`

### Locality Requests

The `address` parameter may match a large feature, such as:

```
https://plus.codes/api?address=Paris&ekey=YOUR_ENCRYPTED_KEY&email=YOUR_EMAIL_HERE
```

In this case, the returned code may not have full precision.
This is because for large features, the returned code will be the **largest** code that fits entirely **within** the bounding box of the feature:

```javascript
{
  "plus_code": {
    "global_code": "8FW4V900+",
    "geometry": {
      "bounds": {
        "northeast": {
          "lat": 48.900000000000006,
          "lng": 2.4000000000000057
        },
        "southwest": {
          "lat": 48.849999999999994,
          "lng": 2.3499999999999943
        }
      },
      "location": {
        "lat": 48.875,
        "lng": 2.375
      }
    }
  },
  "status": "OK"
}
```

## API Keys

### Obtaining A Google API Key
To search for addresses, return addresses, and return short codes and localities, the Plus Codes API uses the [Google Maps Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro).
If you want to be able to:
*  search by address,
*  search by short codes with localities,
*  or have short codes and localities included in responses

you *must* provide a Google API key in your request.
To obtain a Google API key refer [here](https://developers.google.com/maps/documentation/geocoding/start#get-a-key).

Important:
*  The API key *must* have the Google Maps Geocoding API enabled
*  The API key *must* not have any restrictions (referrer, IP address). (This is because it is used to call the web service API, which does not allow restrictions on the key.)

Once you have your API key, you can specify it in requests using the `key` parameter, but you should read the next two sections on securing your key.

### Securing Your API Key

Google API keys have a free daily quota allowance.
If other people obtain your key, they can make requests to any API that is enabled for that key, consuming your free quota, and if you have billing enabled, can incur charges.

The normal way of securing API keys is setting restrictions on the host that can use it to call Google APIs.
These methods won't work here, because the calls to the Google API are being done from the Plus Codes server.

Instead, you can encrypt your Google API key, and use the encrypted value in the requests to the Plus Codes API.
The Plus Codes server will decrypt the key and use the decrypted value to make the calls to Google.

If anyone obtains your encrypted API key, they cannot use it to make direct requests to any Google API. (They can still use it to make requests to the Plus Codes API, see the next section for a solution.)

For example, to protect the Google API key `my_google_api_key`, encrypt it like this:

```
https://plus.codes/api?encryptkey=my_google_api_key
```

The Plus Codes API will respond with:

```javascript
{
  "encryption_message": "Provide the key in the key= parameter in your requests",
  "key": "8Kr54rKYBj8l8DcTxRj7NkvG%2Fe%2FlwvEU%2F4M41bPX3Zmm%2FZX7XoZlsg%3D%3D",
  "status": "OK"
}
```

### Securing Your API Key With An HTTP Referrer

For extra security, you can encrypt a hostname with the key.
When the Plus Codes server decrypts the key, it checks that the HTTP referrer matches the encrypted hostname.
This prevents the encrypted key from being used from another host.

For example, to protect the Google API key `my_google_api_key`, and require the HTTP referrer host to be `openlocationcode.com`, encrypt it like this:

```
https://plus.codes/api?referer=openlocationcode.com&encryptkey=my_google_api_key
```

The Plus Codes API will respond with:

```javascript
{
  "encryption_message": "Provide the key in the key= parameter in your requests",
  "key": "Nn%2BzIy2LOz7sptIe4tkONei3xfO7MUPSyYdoNanqv%2F1wgDaGvUryUDt8EPXRS4xzP%2F0b04b3J6%2BzFeeu",
  "status": "OK"
}
```

#### Allowing Multiple Referrers

If you need to use the same encrypted key from multiple different hosts, say `example1.com` and `example2.com`, include the hosts in the referer like this:

```
https://plus.codes/key?referer=example1.com|example2.com&key=my_google_api_key
```
