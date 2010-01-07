# ensure that we use ../lib/cromwell.rb, not the installed gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cromwell'

puts 'See you in a while...'
Cromwell.protect
sleep 10
Cromwell.unprotect
puts "You're still here?"