module Diecut
  class UIApplier
    attr_accessor :plugins, :ui, :context

    # setup default values on ui
    # setup dynamic defaults on context
    # copy ui settings to context
    # resolve context config
    # confirm required
    def apply
      check_ui
      basic_defaults
      dynamic_defaults
      copy_to_context
      resolve_context
      confirm_required
    end

    def check_ui
      ui.check_required
    end

    def basic_defaults
      context.setup_defaults
    end

    def dynamic_defaults
      plugins.each do |plugin|
        plugin.context_defaults.each do |default|
          apply_dynamic_default(default)
        end
      end
    end

    def copy_to_context
      plugins.each do |plugin|
        plugin.options.each do |option|
          copy_option(option)
        end
      end
    end

    def resolve_context
      plugins.each do |plugin|
        unless plugin.resolve_block.nil?
          plugin.apply_resolve(ui, context)
        end
      end
    end

    def confirm_required
      context.check_required
    end

    def apply_dynamic_default(default)
      return if default.simple?

      segment = context.walk_path(default.context_path).last

      segment.value = default.compute_value(context)
    end

    def copy_option(option)
      return unless option.has_context_path?

      segment = context.walk_path(option.context_path).last

      segment.value = ui.get_value(option.name.to_sym)
    end
  end
end
