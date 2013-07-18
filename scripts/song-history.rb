require 'rubygems'
require 'bundler/setup'
Bundler.require

require 'json'
require 'date'
require 'yaml'

ENV['TZ'] = 'UTC'

config = YAML.load_file('config.yml')

if config['geoloqi_access_token'].nil?
  puts "Missing config.yml"
  exit
end

Geoloqi.config.symbolize_names = false
geoloqi = Geoloqi::Session.new :access_token => config['geoloqi_access_token']

startTS = config['start_time'].to_i
endTS = config['end_time'].to_i


mech = Mechanize.new

puts "Start: #{startTS}";
puts "End: #{endTS}";
puts
puts "Fetching last.fm tracks...";

tracks = RestClient.get "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{config['lastfm_user']}&api_key=#{config['lastfm_apikey']}&format=json&limit=200&from=#{startTS}&to=#{endTS}"
tracks = JSON.parse tracks

if tracks['recenttracks'] and tracks['recenttracks']['track']

  mapData = []
  i = 0

  # The Last.fm API returns an object if there was only one track. Force into an array.
  if tracks['recenttracks']['track'].class != Array
    tracks['recenttracks']['track'] = [tracks['recenttracks']['track']]
  end

  tracks['recenttracks']['track'].each do |track|
    puts track.inspect
    if track['date'] # Only process tracks with a date. recenttracks always returns "now playing" tracks even with a date range set

      puts
      puts "Processing Track: #{track['url']}"
      puts "\tDate: #{Time.at(track['date']['uts'].to_i).strftime('%Y-%m-%d %H:%M:%S')} UTC"
      puts "\tLocal: #{(Time.at(track['date']['uts'].to_i) + Time.zone_offset(config['tz'])).strftime('%Y-%m-%d %H:%M:%S')} UTC"

      # Fetch the track URL and look for a Spotify link in the HTML
      trackPage = mech.get track['url']
      spotifyLink = trackPage.link_with(:href => /http:\/\/www\.last\.fm\/affiliate\/byid\/9\/\d+\/6\/trackpage\/\d+/)
      if spotifyLink
        # The Last.fm page has a URL like http://www.last.fm/affiliate/byid/9/25579963/6/trackpage/25579963
        # Follow the redirects to get the actual spotify.com URL
        spotifyLink = Unshorten.unshorten spotifyLink.href, :short_hosts => false
        puts "\tFound spotify link: #{spotifyLink}"
      end

      # Find the location in Geoloqi within 1 minute of the song time
      location = geoloqi.get 'location/history', {:after => track['date']['uts'].to_i-60, :before => track['date']['uts'].to_i+60, :ignore_gaps => 1, :count => 200}
      if location and location['start']
        mapData << {
          type: "Feature",
          geometry: {
            type: "Point",
            coordinates: [location['start']['location']['position']['longitude'], location['start']['location']['position']['latitude']]
          },
          properties: {
            trackName: track['name'],
            trackAlbum: track['album']['#text'],
            trackArtist: track['artist']['#text'],
            trackURL: track['url'],
            image: track['image'].select{|item| item['size'] == 'large'}.first['#text'],
            localDate: (Time.at(track['date']['uts'].to_i) + Time.zone_offset(config['tz'])).strftime('%Y-%m-%d %H:%M:%S'),
            localDateFormatted: (Time.at(track['date']['uts'].to_i) + Time.zone_offset(config['tz'])).strftime('%b %-d %l:%M%P').gsub(/  /,' '),
            timestamp: track['date']['uts'].to_i,
            spotifyURL: (spotifyLink ? spotifyLink : nil)
          }
        }
      end
    end
  end

  # Write to a file as pretty-json
  File.open("../web/songs.json", 'w') {|f| f.write(JSON.pretty_generate(mapData)) }

  puts 
  puts "Wrote #{mapData.length} tracks to songs.json"

else 
  puts "No tracks found for the given time range"
end

