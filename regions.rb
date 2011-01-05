require 'rubygems'
require 'clipper'



def is_point_in_poly(lat,long, poly, eps=0.01)
  region_poly=poly[:path]
  point_poly = [ [lat - eps, long - eps], [lat - eps, long + eps], [lat + eps, long+eps], [lat + eps, long - eps] ] #Triangle
  c = Clipper::Clipper.new
  
  c.add_subject_polygon(region_poly)
  c.add_clip_polygon(point_poly)
  return !c.intersection.empty?
end



if false
  poly = {:path => [[0,0],[0,100],[100,100],[100,0]] }
  lat = 10 
  long = 10
  p is_point_in_poly(lat,long, poly)
  
  lat = -10 
  long = 10
  p is_point_in_poly(lat,long, poly)
end
