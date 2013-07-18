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


history = geoloqi.get 'location/history', {:after => startTS, :before => endTS, :ignore_gaps => 1, :count => 100000}

coordinates = []
history['points'].each do |point| 
  coordinates << [
    point['location']['position']['longitude'],
    point['location']['position']['latitude']
  ]
end

geoJson = { 
            type: "LineString",
            coordinates: coordinates
          }

File.open("../web/path.json", 'w') {|f| f.write(geoJson.to_json) }

puts "Wrote #{coordinates.length} points to path.json"
