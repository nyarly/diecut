require 'diecut/report-builder'

module Diecut
  module ReportBuilders
    class MissingContextField < ReportBuilder
      def report_name
        "Unused options"
      end

      def report_fields
        ["Output field name", "Option_name", "Plugin name"]
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
        "Options provide values that aren't used by any template"
      end

      def other_advice
        <<-EOA
        Plugins defined options that go to fields that don't appear in templates.

        It's possible that a plugin defined an option for its templates but they were
        overridden, so the fields disappeared. Diecut doesn't yet check for
        that case. In those cases, you can ignore this warning.

        The other possiblity is that the default path has a typo. This is
        especially likely if there's also a report about a missing output
        field. The option might be used in a resolve somewhere, so even if it
        doesn't directly set an output field, it might influence generation
        that way.

        Do be careful to check this option: the option
        EOA
      end
    end
  end
end
