require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cromwell'

class Test::Unit::TestCase
  def assert_slept_at_least seconds, message
    Process.waitpid @pid
    end_time = Time.now
    assert end_time - @start_time >= seconds, message
  end

  def assert_killed_before seconds, message
    Process.waitpid @pid
    end_time = Time.now
    assert end_time - @start_time < seconds, message
  end

  def do_fork &block
    @pid = fork(&block)
  end

  def start
    @start_time = Time.now
    sleep 1 # so the forked process gets to execute protected block
  end
end
