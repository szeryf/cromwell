# ensure that we use ../lib/cromwell.rb, not the installed gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cromwell'

puts 'You can try to kill me but I will survive!'
Cromwell.protect {
  begin
    sleep 10
  ensure
    puts "Oh noes! You wanted to kill me! But I'll continue my work!" if Cromwell.should_exit?
    Cromwell.should_exit = false
  end
}
puts "You're still here?"