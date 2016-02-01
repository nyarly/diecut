require 'diecut/errors'
module Diecut
  class ContextHandler
    attr_accessor :context_class, :ui_class, :plugins

    def apply_simple_defaults
      plugins.each do |plugin|
        plugin.context_defaults.each do |default|
          next unless default.simple?
          begin
            apply_simple_default(default)
          rescue Error
            raise Error, "Plugin #{plugin.name.inspect} failed"
          end
        end
      end
    end

    def apply_to_ui
      plugins.each do |plugin|
        plugin.options.each do |option|
          apply_option_to_ui(option)
        end
      end
    end

    def backfill_options_to_context
      plugins.each do |plugin|
        plugin.options.each do |option|
          backfill_to_context(option)
        end
      end
    end

    def backfill_to_context(option)
      return unless option.has_context_path?

      segment = context_class.walk_path(option.context_path).last
      if option.has_default?
        segment.klass.setting(segment.name, option.default_value)
      else
        segment.klass.setting(segment.name)
      end
    end

    def apply_simple_default(default)
      target = context_class.walk_path(default.context_path).last
      if target.metadata.nil?
        raise UnusedDefault, "No template uses a value at #{default.context_path.inspect}"
      elsif not target.metadata.default_value.nil?
        raise OverriddenDefault, "default for #{default.context_path.inspect} already set to #{target.metadata.default_value.inspect}"
      else
        target.metadata.default_value = default.value
        target.metadata.is(:defaulting)
      end
    end

    def apply_option_to_ui(option)
      ui_class.options_hash[option.name] = option

      if option.has_context_path?
        context_metadata = context_class.walk_path(option.context_path).last.metadata
        if option.has_default?
          ui_class.setting(option.name, option.default_value)
        elsif context_metadata.is?(:defaulting)
          ui_class.setting(option.name, context_metadata.default_value)
        else
          ui_class.setting(option.name)
        end
      else
        if option.has_default?
          ui_class.setting(option.name, option.default_value)
        else
          ui_class.setting(option.name)
        end
      end
    end
  end
end
