require 'diecut/report'

module Diecut
  class Linter
    def initialize(mill)
      @mill = mill
    end
    attr_reader :mill

    def report
      @ui = mill.user_interface

      formatter = ReportFormatter.new([
        option_collision_report,
        orphaned_fields,
        overridden_context_defaults
      ])

      formatter.to_s
    end

    # Needed:
    # Overridden context defaults (without plugin dep)
    # Overridden option defaults (without plugin dep)
    # Option with default, context with default (w/o PD)

    def unindent(text)
      indent = text.grep(/^\s*/).max_by(&:length)
      text.gsub(%r{^#{indent}},'')
    end

    def each_plugin
      mill.mediator.activated_plugins.each do |plugin|
        yield plugin
      end
    end

    def each_default
      each_plugin do |plugin|
        plugin.context_defaults.each do |default|
          yield default, plugin
        end
      end
    end

    def each_option
      each_plugin do |plugin|
        plugin.options.each do |option|
          yield option, plugin
        end
      end
    end

    def overridden_context_defaults
      Report.new("Overridden context defaults", ["Output field", "Default value", "Source plugin"]).tap do |report|
        default_values = Hash.new{|h,k| h[k]=[]}
        each_default do |default, plugin|
          next unless default.simple?

          default_values[default.context_path] << [default, plugin]
        end

        default_values.each_value do |set|
          if set.length > 1
            set.each do |default, plugin|
              report.add(default.context_path.join("."), default.value, plugin.name)
            end
          end
        end

        unless report.empty?
          report.fail("Multiple plugins assign different values to be rendered")
          report.advice = unindent(<<-EOA)
          This is a problem because each plugin may be assuming it's default
          value, and since there's no guarantee in which order the plugins are
          loaded, the actual default value is difficult to predict. In general,
          this kind of override behavior can be difficult to reason about.

          Either the collision is accidental, in which case the default value
          should be removed from one plugin or the other. If the override is
          intentional, then the overriding plugin's gem should depend on the
          overridden one's - since you are overriding the value intentionally,
          it makes sense to ensure that the value is there to override. Diecut
          will load plugins such that the dependant plugins are loaded later,
          which solves the predictability problem.
          EOA
        end
      end
    end

    def option_collision_report
      report = Report.new("Option collisions", ["Output target", "Option name", "Source plugin"])

      option_targets = Hash.new{|h,k| h[k]=[]}
      mill.mediator.activated_plugins.each do |plugin|
        plugin.options.each do |option|
          next unless option.has_context_path?
          option_targets[option.context_path] << [plugin, option]
        end
      end
      option_targets.each_value do |set|
        if set.length > 1
          set.each do |plugin, option|
            report.add(option.context_path.join("."), option.name, plugin.name)
          end
        end
      end

      unless report.empty?
        report.fail("Multiple options assign the same values to be rendered")
        report.advice = (<<-EOA).gsub(/^      /,'')
        This is problem because two options in the user interface both change
        rendered values. If a user supplies both with different values, the
        output isn't predictable (either one might take effect).

        Most likely, this is a simple error: remove options from each group
        that targets the same rendered value until only one remains. It may
        also be that one option has a typo - that there's a rendering target
        that's omitted.
        EOA
      end

      report
    end

    def orphaned_fields
      Report.new("Template fields all have settings", ["Output field", "Source file"]).tap do |report|
        ui_class = mill.ui_class
        context_class = mill.context_class

        required_fields = {}

        context_class.field_names.each do |field_name|
          if context_class.field_metadata(field_name).is?(:required)
            required_fields[field_name.to_s] = []
          end
        end

        mill.templates.all_templates.each do |template|
          template.reduced.leaf_fields.each do |field|
            field = field.join(".")
            if required_fields.has_key?(field)
              required_fields[field] << template.path
            end
          end
        end

        mill.mediator.activated_plugins.each do |plugin|
          plugin.options.each do |option|
            next unless option.has_context_path?
            field = option.context_path.join(".")
            required_fields.delete(field)
          end
        end

        required_fields.each do |name, targets|
          targets.each do |target|
            report.add(name, target)
          end
        end

        unless report.empty?
          report.status = "WARN"
          report.advice = (<<-EOA).gsub(/^        /,'')
          These fields might not receive a value during generation, which will
          raise an error at use time.

          It's possible these fields are set in a resolve block in one of the
          plugins - Diecut can't check for that yet.
          EOA
        end
      end
    end
  end
end
