module Diecut
  module ErrorHandling
    class Base
      def missing_context_field_message(option_name, context_path)
        "No template uses a value at #{context_path.inspect}, provided by #{option_name}"
      end

      def unused_default_message(context_path)
        "No template uses a value at #{context_path.inspect}, provided as a default"
      end

      def invalid_plugin_message(name, context_path, value)
        "Default on #{context_path.inspect} from plugin #{name} has both a simple default value (#{value}) and a dynamic block value, which isn't allowed."
      end

      def missing_context_field(plugin_name, option_name, context_path)
        issue(missing_context_field_message(option_name, context_path))
      end

      def unused_default(plugin_name, context_path)
        issue(usused_default_message(context_path))
      end

      def invalid_plugin(name, context_path, value)
        issue invalid_plugin_message(name, context_path, value)
      end

      def handle_exception(ex)
        if Error === ex
          issue(ex.message)
        else
          raise
        end
      end
    end

    class Silent < Base
      def issue(message)
      end
    end

    class AllWarn < Base
      def issue(message)
        warn message
      end
    end

    class FatalRaise < AllWarn
      def invalid_plugin(name, context_path, value)
        raise InvalidPlugin, invalid_plugin_message(name, context_path, value)
      end
    end

    class AllRaise < FatalRaise
      def handle_exception(ex)
        raise
      end

      def missing_context_field(option_name, context_path)
        raise MissingContext, missing_context_field_message(option_name, context_path)
      end

      def unused_default(context_path)
        raise UnusedDefault, unused_default_message(context_path)
      end
    end
  end

  class Error < RuntimeError;
    def message
      if cause.nil?
        super
      else
        super + " because: #{cause.message}"
      end
    end
  end
  class UnusedDefault < Error; end
  class MissingContext < Error; end
  class OverriddenDefault < Error; end
  class InvalidPlugin < Error; end
  class FieldClash < Error; end
end
