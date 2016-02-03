require 'diecut/report-builder'

module Diecut
  module ReportBuilders
    class OptionCollisions < ReportBuilder
      register

      def report_name
        "Option collisions"
      end

      def report_fields
        ["Output target", "Option name", "Source plugin"]
      end

      def collect
        option_targets = Hash.new{|h,k| h[k]=[]}
        each_option do |option, plugin|
          next unless option.has_context_path?
          option_targets[option.context_path] << [plugin, option]
        end
        option_targets.each_value do |set|
          if set.length > 1
            set.each do |plugin, option|
              report.add(option.context_path.join("."), option.name, plugin.name)
            end
          end
        end
      end

      def fail_summary
        "Multiple options assign the same values to be rendered"
      end

      def fail_advice
        (<<-EOA)
          This is problem because two options in the user interface both change
          rendered values. If a user supplies both with different values, the
          output isn't predictable (either one might take effect).

          Most likely, this is a simple error: remove options from each group
          that targets the same rendered value until only one remains. It may
          also be that one option has a typo - that there's a rendering target
          that's omitted.
        EOA
      end
    end
  end
end
