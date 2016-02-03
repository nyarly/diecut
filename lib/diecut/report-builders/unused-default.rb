require 'diecut/report-builder'

module Diecut
  module ReportBuilders
    class UnusedDefault < ReportBuilder
      def report_name
        "Defaults are declared but unused"
      end

      def report_fields
        ["Output field name", "Plugin name"]
      end

      def report_status
        report.empty? ? "OK" : "WARN"
      end

      def collect
      end

      def add(*args)
        report.add(*args)
      end

      def other_summary
        "Defaults are defined for fields that don't exist in output templates"
      end

      def other_advice
        <<-EOA
        Plugins defined defaults for fields that don't appear in templates.

        It's possible that a plugin defined a default but it's template was
        overridden, so the fields disappeared. Diecut doesn't yet check for
        that case. In those cases, you can ignore this warning.

        The other possiblity is that the default path has a typo. This is
        especially likely if there's also a report about a missing output
        field.
        EOA
      end
    end
  end
end
