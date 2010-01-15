class Cromwell
  DEFAULT_SIGNAL_LIST = %w[INT TERM HUP QUIT].freeze

  @logger      = nil
  @should_exit = false
  @protected   = false
  @old_traps   = {}

  class << self
    # Something to log Cromwell's messages if you like. This can be a +Logger+ or any other class that
    # accepts #debug and #info messages. Default value is +nil+.
    attr_accessor :logger

    # True when the script will be terminated after protected block, i.e. when a signal
    # was caught that was protected from. You can set it to false to prevent script from
    # termination even if a signal was caught.
    attr_accessor :should_exit
    alias_method  :should_exit?, :should_exit

    # True if the protection is currently active.
    attr_reader  :protected
    alias_method :protected?, :protected

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
    def protect *signals, &block
      debug "Protect called with [#{signals * ', '}]"
      set_up_traps(signals.empty? ? DEFAULT_SIGNAL_LIST : signals.flatten)
      @should_exit = false
      @protected   = true
      protect_block(&block) if block_given?
    end

    # call-seq:
    #   Cromwell.unprotect
    #
    # Turns off protection from signals. Will terminate the script with <code>Kernel#exit</code>
    # if signal was caught earlier (so any <code>at_exit</code> code will be executed).
    # The protect method calls this automatically when executed with a block.
    def unprotect
      debug "Unprotect called, should_exit? = #{@should_exit}"
      @protected = false
      if @should_exit
        info "Exiting because should_exit is true"
        exit
      else
        restore_old_traps
      end
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
      trap(signal) { handle signal }
    end

    def handle signal
      if @protected
        info "Caught signal #{signal} -- ignoring."
        @should_exit = true
        "IGNORE"
      else
        exit
      end
    end

    def stash old_trap, signal
      debug "Stashing old trap #{old_trap} for #{signal}"
      @old_traps[signal] = old_trap
    end

    def restore_old_traps
      @old_traps.each do |signal, old_trap|
        debug "Restoring old trap #{old_trap} for #{signal}"
        trap signal, old_trap
      end
      @old_traps = {}
    end

    def debug msg
      @logger.debug msg if @logger
    end

    def info msg
      @logger.info msg if @logger
    end

    def protect_block &block
      begin
        debug "About to yield to block."
        yield
        debug "After yielding to block."
      ensure
        unprotect
      end
    end
  end
end
