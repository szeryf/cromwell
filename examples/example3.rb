require 'rubygems'
require 'cromwell'

puts "You can't stop me with ^C but you can kill me. My pid is #{$$}."
Cromwell.protect("INT") {
  sleep 10
}
puts "You're still here?"