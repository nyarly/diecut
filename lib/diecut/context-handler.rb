require 'diecut/errors'
module Diecut
  class ContextHandler
    attr_accessor :context_class, :ui_class, :plugins

    def issue_handler
      @issue_handler ||= Diecut.issue_handler
    end
    attr_writer :issue_handler

    def apply_simple_defaults
      plugins.each do |plugin|
        plugin.context_defaults.each do |default|
          next unless default.simple?
          begin
            apply_simple_default(plugin, default)
          rescue Error
            raise Error, "Plugin #{plugin.name.inspect} failed"
          end
        end
      end
    end

    def apply_to_ui
      plugins.each do |plugin|
        plugin.options.each do |option|
          apply_option_to_ui(plugin, option)
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

    def apply_simple_default(plugin, default)
      target = context_class.walk_path(default.context_path).last
      if target.metadata.nil?
        issue_handler.unused_default(plugin.name, context_path)
      else
        target.metadata.default_value = default.value
        target.metadata.is(:defaulting)
      end
    end

    def apply_option_to_ui(plugin, option)
      ui_class.options_hash[option.name] = option

      if option.has_context_path?
        context_metadata = context_class.walk_path(option.context_path).last.metadata
        if context_metadata.nil?
          issue_handler.missing_context_field(plugin.name, option.name, option.context_path)
          return
        end
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
