module Diecut
  class PluginDescription
    class Option
      def initialize(name)
        @name = name
        @default_value = NO_VALUE
      end
      attr_reader :name, :description, :context_path, :default_value

      def has_default?
        default_value != NO_VALUE
      end

      def has_context_path?
        !context_path.nil?
      end

      # A description for the option in the user interface.
      # @param desc [String]
      #   The description itself
      def description(desc = NO_VALUE)
        if desc == NO_VALUE
          return @description
        else
          @description = desc
        end
      end

      # Defines the templating context path this value should be copied to.
      # @param context_path [Array,String]
      #   The path into the context to set from this option's value.
      #
      # @example Three equivalent calls
      #   option.goes_to("deeply.nested.field")
      #   option.goes_to(%w{deeply nested field})
      #   option.goes_to("deeply", "nested", "field")
      def goes_to(*context_path)
        if context_path.length == 1
          context_path =
            case context_path.first
            when Array
              context_path.first
            when /.+\..+/ # has an embedded .
              context_path.first.split('.')
            else
              context_path
            end
        end

        @context_path = context_path
      end

      # Gives the option a default value (and therefore makes it optional for
      # the user to provide)
      #
      # @param value
      #   The default value
      def default(value)
        @default_value = value
      end
    end
  end
end
