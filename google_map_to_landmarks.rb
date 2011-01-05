require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'yaml'

map_url='http://maps.google.com/maps/ms?ie=UTF8&hl=en&vps=1&jsv=304e&msa=0&output=georss&msid=202933467189883314896.00049912d6823abb690f2'

doc = Nokogiri::XML( open(map_url) )

paths = []
doc.xpath('//item[gml:LineString]').each do |path|
  landmark_name = path.xpath("title").first.text
  path = path.xpath("gml:LineString/gml:posList").first.text
  long_lat_path = path.strip.split("\n").map {|l| l.strip.split(' ').map {|v| v.to_f}}
  paths << {:name => landmark_name, :path =>long_lat_path, :type => 'path'}
end

doc.xpath('//item[gml:Polygon]').each do |path|
  landmark_name = path.xpath("title").first.text
  path = path.xpath("gml:Polygon/gml:exterior/gml:LinearRing/gml:posList").first.text
  long_lat_path = path.strip.split("\n").map {|l| l.strip.split(' ').map {|v| v.to_f}}
  paths << {:name => landmark_name, :path =>long_lat_path, :type => 'path'}
end

puts YAML.dump(paths)
