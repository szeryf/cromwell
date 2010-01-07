class Cromwell
  DEFAULT_SIGNAL_LIST = %w[INT TERM HUP QUIT].freeze

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
      set_up_traps(signals.empty? ? DEFAULT_SIGNAL_LIST : signals.flatten)
      @@should_exit = false
      @@protected   = true
      if block_given?
        begin
          yield
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
      @@protected = false
      exit if @@should_exit
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
    #   Cromwell.should_exit = bool
    #
    # Set to false to prevent script from termination even if a signal was caught. You can also set
    # this to true to have your script terminated after protected block should you wish so.
    def should_exit= b
      @@should_exit = b
    end

    # call-seq:
    #   Cromwell.protected?
    #
    # True if the protection is currently active.
    def protected?
      @@protected
    end

  private
    def set_up_traps signals
      signals.each { |signal| set_up_trap signal }
    end

    def set_up_trap signal
      trap signal do
        if @@protected
          #puts "Just a minute now."
          @@should_exit = true
          "IGNORE"
        else
          exit
        end
      end
    end
  end
end
