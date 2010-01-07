# ensure that we use ../lib/cromwell.rb, not the installed gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cromwell'

puts "You can't stop me with ^C but you can kill me. My pid is #{$$}."
Cromwell.protect("INT") {
  sleep 10
}
puts "You're still here?"