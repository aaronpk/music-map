jQuery(function(){

  var map = L.map('playlist-map', {maxZoom: 16});
  L.esri.basemapLayer("Gray").addTo(map);
  L.esri.basemapLayer("GrayLabels").addTo(map);

  // Add the line of the trip history to the map
  $.getJSON("path.json", function(path){
    L.geoJson(path).addTo(map);
  });

  $.getJSON("songs.json", function(songs){
    // Build a layer of the songs and set up a popup when the marker is clicked
    var geoJsonLayer = L.geoJson(songs, {
      onEachFeature: function(feature, layer) {
        var popupHtml = '<img src="' + feature.properties.image + '" width="60" style="float: right;" /><div style="width: 200px;"><b><a href="' + feature.properties.trackURL + '" target="_blank">' + feature.properties.trackName + '</a></b><br />' + feature.properties.trackArtist + '<br />';
        popupHtml += feature.properties.localDateFormatted + '<br />';
        if(feature.properties.spotifyURL) {
          popupHtml += '<a href="' + feature.properties.spotifyURL + '" target="_blank">Play on Spotify</a><br />';
        }
        popupHtml += '</div>';
        layer.bindPopup(popupHtml);
      }
    });
    geoJsonLayer.addTo(map);

    // Fit the map to encompass all the markers
    map.fitBounds(geoJsonLayer.getBounds());
  });

});
