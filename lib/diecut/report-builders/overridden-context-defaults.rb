require 'diecut/report-builder'

module Diecut
  module ReportBuilders
    class OverriddenContextDefaults < ReportBuilder
      register

      def report_name
        "Overridden context defaults"
      end

      def report_fields
        ["Output field", "Default value", "Source plugin"]
      end

      def collect
        default_values = Hash.new{|h,k| h[k]=[]}
        each_default do |default, plugin|
          next unless default.simple?

          default_values[default.context_path] << [default, plugin]
        end

        default_values.each do |key, set|
          default_values[key] = set.find_all do |plugin|
            !set.any?{|child| strict_sequence?(plugin[1], child[1]) }
          end
        end

        default_values.each_value do |set|
          if set.length > 1
            set.each do |default, plugin|

              report.add(default.context_path.join("."), default.value, plugin.name)
            end
          end
        end
      end

      def fail_summary
        "Multiple plugins assign different values to be rendered by default"
      end

      def fail_advice
        (<<-EOA)
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
end
