require 'rubygems'
require 'cromwell'

puts 'See you in a while...'
Cromwell.protect {
  sleep 10
}
puts "You're still here?"