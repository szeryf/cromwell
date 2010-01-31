# ensure that we use ../lib/cromwell.rb, not the installed gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cromwell'

Cromwell.custom_traps["INT"] = proc {
  puts "Trying your ^C skills, are you?"
}

Cromwell.custom_traps["QUIT"] = proc {
  puts "We'll be leaving soon!"
  Cromwell.should_exit = true
}

puts 'See you in a while...'
Cromwell.protect {
  sleep 10
}
puts "You're still here?"