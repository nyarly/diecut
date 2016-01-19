module Diecut
  class Error < RuntimeError;
    def message
      if cause.nil?
        super
      else
        super + "because: #{cause.message}"
      end
    end
  end
  class UnusedDefault < Error; end
  class OverriddenDefault < Error; end
  class InvalidConfig < Error; end
end
