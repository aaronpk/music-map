Music Map
=========

This is the code used to generate the map in my blog post, http://aaronparecki.com/articles/2013/07/17/1/how-i-mapped-all-the-songs-we-listened-to-on-a-road-trip

This repository ships with the data I used for my post, but you can easily run the scripts to generate your own map and playlists.

Usage
-----

From the `scripts` folder, run `bundle install` to install the needed Ruby gems.

You'll need to copy `config.yml.template` to `config.yml` and fill in your details. You'll need to set:

* your Geoloqi access token
* your Last.fm username and API key
* your local timezone of the trip
* the start and end dates of the trip as full ISO8601 dates

You'll need to install the following gems

Run the `location-history.rb` file to export your history from Geoloqi to a GeoJSON file.

Run `song-history.rb` to fetch all the tracks played on your Last.fm account during the trip. For each track, your Geoloqi account will be queried to get the location at the time the song was played. The script will also try to find the Spotify URL on the Last.fm song page. This script takes a while since there are so many HTTP requests needed to get all the data.

Afterwards, you'll end up with two files in the "web" folder: `path.json` and `songs.json`. You should then be able to open launch the index.html file in a browser and see the map!

Note: You will need to view this with a real hostname, not just a `file://` URL, since the browser won't load the .json files unless they're served via a hostname. One of the easiest ways is to run [http://anvilformac.com/ Anvil], or you can use your computer's built-in web server.
