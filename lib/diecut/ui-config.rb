require 'diecut/configurable'
module Diecut
  class UIConfig < Configurable
    class << self
      def options_hash
        @options_hash ||= {}
      end

      def description(name)
        @options_hash.fetch(name).description
      end

      def required?(name)
        field_metadata(name).is?(:required)
      end

      def default_for(name)
        field_metadata(name).default_value
      end
    end

    def initialize
      super
      setup_defaults
    end

    def get_value(name)
      self.class.field_metadata(name).value_on(self)
    end
  end
end
