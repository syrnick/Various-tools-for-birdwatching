require 'rubygems'
require 'nokogiri'
require 'set'

doc = File.open('/Users/syrnick/Desktop/birds/summary.html','r') do |file|
  Nokogiri::HTML( file.read )
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


counties = Set.new( ["San Mateo","Santa Clara", "Santa Cruz", "Alameda", "Contra Costa", "Solano", "Napa", "Sonoma", "Marin", "San Francisco"] )

results = tr_all.map do |tr|
  a = tr.css('a.map')[0]
  url = a["href"]
  (long,lat) = url.split("&")[-1].split("=")[1].split(",")
  location = tr.css("td.location").first.child.text

  species = tr.css("td.species-name").inner_text
  count = [tr.css("td.count").inner_text.to_i,1].max

  county = tr.css("td.county").inner_text

  if counties.include? county
    { :county => county,
      :count => count,
      :species => species,
      :long => long,
      :lat => lat,
      :location => location,
      :url => url,
      :tr => tr}
  else
    nil
  end
end.compact
  
results.sort! { |a,b| 
  first = a[:county] <=> b[:county]
  if first != 0
    first
  else
    a[:location] <=> b[:location]
  end
}
    
results.each do |place|
  puts "#{place[:county]},\"#{place[:location]}\",#{place[:species]},#{place[:count]},\"#{place[:url]}\""
end
