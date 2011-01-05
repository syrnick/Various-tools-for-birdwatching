require 'rubygems'
require 'nokogiri'
require 'set'
require 'YAML'
require 'geo_distance'
require 'fastercsv'
require 'regions'

if ARGV.size < 2
  p "Usage: birds.rb observations_file landmarks_file"
  exit
end

POI_RADIUS = 1.67

counties_of_interest = ["San Mateo","Santa Clara", "Santa Cruz", "Alameda", "Contra Costa", "Solano", "Napa", "Sonoma", "Marin", "San Francisco"] 
#counties_of_interest = ["Westchester", "Bronx", "Rockland", "Orange", "Putnam"]
observations_file = ARGV[0] || "./summary.html"
landmarks_file = ARGV[1] 

doc = File.open(observations_file,'r') do |file|
  Nokogiri::HTML( file.read )
end

if landmarks_file
  all_landmarks = File.open( landmarks_file ) {|lf| YAML.load(lf)}
  point_landmarks = all_landmarks.select {|lm| lm[:type].nil? || lm[:type]=='point'}
  region_landmarks = all_landmarks.select {|lm| lm[:type]=='path' }
  landmarks = {:point => point_landmarks, :region => region_landmarks}
else
  landmarks = nil
end

####
# Search for nodes by xpath
#
tr_all=[]
doc.css('#sightingsTable tbody tr.specLtblue').each do |tr|
  tr_all << tr;
end
doc.css('#sightingsTable tbody tr.specWhite').each do |tr|
  tr_all << tr;
end

def find_landmark(all_landmarks,lat,long)
  return nil if all_landmarks.nil?

  f_lat = lat.to_f
  f_long = long.to_f

  landmarks = all_landmarks[:point]
  if landmarks
    all_dist_to_landmark = landmarks.map {|l| [l["name"],Distance.geo_distance(l["lat"],l["long"],f_lat,f_long)]}
    best_landmark = landmarks.map {|l| [l["name"],Distance.geo_distance(l["lat"],l["long"],f_lat,f_long)]}.min {|a,b| a[1] <=> b[1] }
    if best_landmark && best_landmark[1] <= POI_RADIUS
      return best_landmark[0]
    end
  end
  
  poly_landmarks = all_landmarks[:region]
  best_poly = poly_landmarks.find do |poly|
    is_point_in_poly(f_lat, f_long, poly)
  end
  return best_poly[:name] if best_poly
end

counties = Set.new( counties_of_interest )

results = tr_all.map do |tr|
  a = tr.css('a.map')[0]
  url = a["href"]
  (lat,long) = url.split("&")[-1].split("=")[1].split(",")
  location = tr.css("td.location").first.child.text

  species = tr.css("td.species-name").inner_text
  count = [tr.css("td.count").inner_text.to_i,1].max

  county = tr.css("td.county").inner_text
  date = tr.css("td.date").inner_text
  observer = tr.css("td.observer").inner_text.strip

  if counties.include? county
    { :county => county,
      :count => count,
      :species => species,
      :lat => lat,
      :long => long,
      :location => location,
      :date => date,
      :landmark => find_landmark(landmarks,lat,long),
      :observer => observer,
      :url => url,
      :tr => tr}
  else
    nil
  end
end.compact


def normal_order(a,b)
  first = a[:county] <=> b[:county]
  if first != 0
    first
  else
    a[:species] <=> b[:species]
  end
end
  
results.sort! { |a,b| 
  if a[:landmark].nil?
    if b[:landmark].nil?
      normal_order(a,b)
    else
      1
    end
  elsif b[:landmark].nil?
    -1
  else
    first = a[:landmark] <=> b[:landmark]
    if first == 0
      normal_order(a,b)
    else
      first
    end
  end
}

FCSV do |csv_out| 
  csv_out << [ :landmark, :county, :location, :species, :count, :url, :lat, :long, :date, :observer ]
  results.each do |place|
    csv_out << [:landmark, :county, :location, :species, :count, :url, :lat, :long, :date, :observer].map {|t| place[t]} 
  end
end
