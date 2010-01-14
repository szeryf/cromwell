class Cromwell
  DEFAULT_SIGNAL_LIST = %w[INT TERM HUP QUIT].freeze

  @@logger      = nil
  @@should_exit = false
  @@protected   = false
  @@old_traps   = {}

  class << self
    # call-seq:
    #   Cromwell.protect(*signals) { ... some code ... }
    #   Cromwell.protect(*signals)
    #   Cromwell.protect { ... some code ... }
    #   Cromwell.protect
    #
    # Starts protecting your code. If called with a block, only the code within a block is
    # executed with signal protection. Without a block, script is protected until unprotect
    # is called. Signals can be given in all the forms that <code>Signal#trap</code> recognizes.
    # Without parameters, the code is protected from the signals in DEFAULT_SIGNAL_LIST.
    # More info and examples in README.rdoc.
    def protect *signals
      debug "Protect called with [#{signals * ', '}]"
      set_up_traps(signals.empty? ? DEFAULT_SIGNAL_LIST : signals.flatten)
      @@should_exit = false
      @@protected   = true
      if block_given?
        begin
          debug "About to yield to block."
          yield
          debug "After yielding to block."
        ensure
          unprotect
        end
      end
    end

    # call-seq:
    #   Cromwell.unprotect
    #
    # Turns off protection from signals. Will terminate the script with <code>Kernel#exit</code>
    # if signal was caught earlier (so any <code>at_exit</code> code will be executed).
    # The protect method calls this automatically when executed with a block.
    def unprotect
      debug "Unprotect called"
      @@protected = false
      debug "should_exit? = #{@@should_exit}"
      if @@should_exit
        info "Exiting because should_exit is true"
        exit
      end
      restore_old_traps
    end

    # call-seq:
    #   Cromwell.should_exit?
    #
    # True when the script will be terminated after protected block, i.e. when a signal
    # was caught that was protected from.
    def should_exit?
      @@should_exit
    end

    # call-seq:
    #   Cromwell.should_exit = boolean
    #
    # Set to false to prevent script from termination even if a signal was caught. You can also set
    # this to true to have your script terminated after protected block should you wish so.
    def should_exit= boolean
      @@should_exit = boolean
    end

    # call-seq:
    #   Cromwell.protected?
    #
    # True if the protection is currently active.
    def protected?
      @@protected
    end

    # call-seq:
    #   Cromwell.logger
    #
    # Returns logger. There is no default logger, so if you haven't set this before, it will be nil.
    def logger
      @@logger
    end

    # call-seq:
    #   Cromwell.logger = some_logger
    #
    # Set a logger for Cromwell.
    def logger= logger
      @@logger = logger
    end

  private
    def set_up_traps signals
      signals.each do |signal|
        old_trap = set_up_trap signal
        stash old_trap, signal
      end
    end

    def set_up_trap signal
      debug "Setting trap for #{signal}"
      trap signal do
        if @@protected
          info "Caught signal #{signal} -- ignoring."
          @@should_exit = true
          "IGNORE"
        else
          info "Caught signal #{signal} -- exiting."
          exit
        end
      end
    end

    def stash old_trap, signal
      debug "Stashing old trap #{old_trap} for #{signal}"
      @@old_traps[signal] = old_trap
    end

    def restore_old_traps
      @@old_traps.each do |signal, old_trap|
        debug "Restoring old trap #{old_trap} for #{signal}"
        trap signal, old_trap
      end
      @@old_traps = {}
    end

    def debug msg
      @@logger.debug msg if @@logger
    end

    def info msg
      @@logger.info msg if @@logger
    end
  end
end
