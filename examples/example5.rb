# ensure that we use ../lib/cromwell.rb, not the installed gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cromwell'

Signal.trap("INT") { puts "Original signal handler!" }

puts 'See you in a while...'
Cromwell.protect {
  sleep 1
}
puts "Try to ^C now to see original signal handler in action!"
sleep 10
