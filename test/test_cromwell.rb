require 'helper'

class TestCromwell < Test::Unit::TestCase

  # The tests below are hackish and slow, because I had to use sleep to find out whether
  # forked process was killed or not. If you know a better (and portable!) way to do it,
  # please let me know.
  #
  # On my OS X 10.5:
  # - Process.kill always returns 1
  # - Process.waitpid(@pid) always returns @pid
  # - Process.waitpid(@pid, Process::WNOHANG) always returns nil
  # so these methods cannot be used to determine if the forked process is still alive :(

  PROCS = {
    "block form" => proc {
      Cromwell.protect("HUP") { sleep 3 }
    },
    "non block form" => proc {
      Cromwell.protect "HUP"
      sleep 3
      Cromwell.unprotect
    },
  }

  PROCS.each do |name, code|
    context "general functionality of #{name}" do
      setup do
        do_fork &code
        start
      end

      should "protect from given signal" do
        Process.kill("HUP", @pid)
        assert_slept_at_least 3, "child should not be killed before 3 seconds"
      end

      should "not protect from other signals" do
        Process.kill("TERM", @pid)
        assert_killed_before 3, "child should be killed before 3 seconds"
      end
    end
  end

  context "general functionality" do
    PROCS2 = {
      "block form" => proc {
        Cromwell.protect { sleep 3 }
      },
      "non block form" => proc {
        Cromwell.protect
        sleep 3
        Cromwell.unprotect
      },
    }

    PROCS2.each do |name, code|
      context name do
        should "protect from default signals" do
          do_fork &code
          start

          Cromwell::DEFAULT_SIGNAL_LIST.each do |signal|
            Process.kill(signal, @pid)
          end
          assert_slept_at_least 3, "child should not be killed before 3 seconds"
        end

        should "exit right after protected block" do
          do_fork {
            code.call
            sleep 10
          }
          start

          Process.kill("HUP", @pid)
          assert_killed_before  4, "child should be killed after 3 seconds"
        end
      end
    end
  end # general functionality

  context "original traps" do
    should "be restored" do
      im_in_ur_blok_touchin_ur_vars = false
      Signal.trap("HUP") {
        im_in_ur_blok_touchin_ur_vars = true
      }
      Cromwell.protect {
        im_in_ur_blok_touchin_ur_vars = :maybe?
      }
      Process.kill("HUP", $$)
      assert im_in_ur_blok_touchin_ur_vars
    end
  end

  context "method protect" do
    should "set up trap with given signals" do
      Cromwell.expects(:set_up_traps).with(["HUP", "TERM"])
      Cromwell.protect "HUP", "TERM"
    end

    should "set up trap with default signals" do
      Cromwell.expects(:set_up_traps).with(Cromwell::DEFAULT_SIGNAL_LIST)
      Cromwell.protect
    end

    should "assign false to should_exit" do
      Cromwell.protect
      assert !Cromwell.should_exit?
    end

    should "assign true to protected" do
      Cromwell.protect
      assert Cromwell.protected?
    end

    context "with a logger" do
      setup do
        @log = stub :debug => true
        Cromwell.logger = @log
      end

      teardown do
        Cromwell.logger = nil
      end

      should "log about being called" do
        @log.expects(:debug).with("Protect called with []")
        Cromwell.protect { i = 1 }
      end

      should "log about being called with parameters" do
        @log.expects(:debug).with("Protect called with [HUP, TERM]")
        Cromwell.protect("HUP", "TERM") { i = 1 }
      end

      should "log about setting traps" do
        @log.expects(:debug).with("Setting trap for HUP")
        @log.expects(:debug).with("Setting trap for TERM")
        Cromwell.protect("HUP", "TERM") { i = 1 }
      end

      should "log about stashing old traps" do
        Signal.trap "HUP", proc {}
        Signal.trap "TERM", "DEFAULT"
        @log.expects(:debug).with(regexp_matches(/^Stashing old trap #<Proc:.+> for HUP$/))
        @log.expects(:debug).with('Stashing old trap DEFAULT for TERM')
        Cromwell.protect("HUP", "TERM") { i = 1 }
      end

      should "log about restoring old traps" do
        Signal.trap "HUP", proc {}
        Signal.trap "TERM", "DEFAULT"
        @log.expects(:debug).with(regexp_matches(/^Restoring old trap #<Proc:.+> for HUP$/))
        @log.expects(:debug).with('Restoring old trap DEFAULT for TERM')
        Cromwell.protect("HUP", "TERM") { i = 1 }
      end
    end # with a logger

  end # method protect

  context "method protect with a block" do
    should "yield to block" do
      im_in_ur_blok_touchin_ur_vars = false
      Cromwell.protect {
        im_in_ur_blok_touchin_ur_vars = true
      }
      assert im_in_ur_blok_touchin_ur_vars
    end

    should "call unprotect after block is finished" do
      Cromwell.protect { i = 1 }
      assert !Cromwell.protected?
    end

    should "assign true to protected inside block" do
      Cromwell.protect {
        assert Cromwell.protected?
      }
    end

    context "with a logger" do
      setup do
        @log = stub :debug => true
        Cromwell.logger = @log
      end

      teardown do
        Cromwell.logger = nil
      end

      should "log before yield" do
        @log.expects(:debug).with('About to yield to block.')
        Cromwell.protect { i = 1 }
      end

      should "log after yield" do
        @log.expects(:debug).with('After yielding to block.')
        Cromwell.protect { i = 1 }
      end
    end # with a logger

  end # method protect with block

  context "method unprotect" do
    should "assign false to protected" do
      Cromwell.protect
      Cromwell.unprotect
      assert !Cromwell.protected?
    end

    should "terminate if should_exit is true" do
      Cromwell.should_exit = true
      Cromwell.expects(:exit)
      Cromwell.unprotect
    end

    context "with a logger" do
      setup do
        @log = stub :debug => true
        Cromwell.logger = @log
        Cromwell.should_exit = false
      end

      teardown do
        Cromwell.logger = nil
      end

      should "log about being called" do
        @log.expects(:debug).with("Unprotect called")
        Cromwell.unprotect
      end

      should "log about should_exit value" do
        @log.expects(:debug).with("should_exit? = false")
        Cromwell.unprotect
      end
    end # with a logger
  end # method unprotect

  context "should_exit=" do
    should "prevent script from terminating if set to false" do
      Cromwell.should_exit = false
      Cromwell.expects(:exit).never
      Cromwell.unprotect
    end
  end

end
