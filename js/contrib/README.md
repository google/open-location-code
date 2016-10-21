# Contributions

## Google Maps API Grid Overlay

The `contrib` directory includes `olc_grid_overlay.js` (also a minified version). This allows you to plot an Open Location Code grid on top of a embedded Google Map.

As you pan or zoom the map, the grid and labels are redrawn.

### Adding the overlay

```javascript
// After you have created the Google Maps object, instantiate
// the grid overlay, passing it the map object.
var overlay = new OLCGridOverlay({map: map});

// Alternatively, use the setMap() method.
var overlay = new OLCGridOverlay();
overlay.setMap(map);
```

### Configuring the overlay

The options object specification is as follows:
|Properties||
|:--|:--|
| **map** | **Type: [Map](https://developers.google.com/maps/documentation/javascript/3.exp/reference#Map)**|
| **minorGridDisplay** |**Type: boolean** Whether to display the minor grid and row/column grid labels. Defaults to **true**.|
| **roadMapColor** |**Type: String** The stroke color to use for the grid lines over road or terrain maps. All CSS3 colors are supported except for extended named colors.|
| **roadMapLabelClass** |**Type: String** The CSS class name to use for text labels over road or terrain maps. Defaults to **olc_overlay_text**.|
| **satelliteMapColor** |**Type: String** The stroke color to use for the grid lines over satellite or hybrid maps. All CSS3 colors are supported except for extended named colors.|
| **satelliteMapLabelClass** |**Type: String** The CSS class name to use for text labels over satellite or hybrid maps. Defaults to **olc_overlay_text**.|

### Styling labels
The text labels default to using the CSS class selector `.olc_overlay_text`. If there is no CSS style with that selector, one will be automatically added to the document. If you want to specify your own style, you should ensure it includes the following settings:

```html
text-align: center;
position: fixed;
display: flex;
justify-content: center;
flex-direction: column;
```

It's a really good idea to use slightly different styles for the road and satellite maps with different text colors. This is because of the different colors used in the maps.

Here is an example of two styles:
```html
  <style>
   .olc_label_road {
      font-family: Roboto, sans;
      font-weight: 400;
      color: #7BAAF7;
      text-align: center;
      position: fixed;
      display: flex;
      justify-content: center;
      flex-direction: column;
   }
   .olc_label_sat {
      font-family: Roboto, sans;
      font-weight: 400;
      color: #3376E1;
      text-align: center;
      position: fixed;
      display: flex;
      justify-content: center;
      flex-direction: column;
   }
  </style>
```
