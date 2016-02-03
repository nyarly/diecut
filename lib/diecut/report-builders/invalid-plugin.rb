require 'diecut/report-builder'

module Diecut
  module ReportBuilders
    class InvalidPlugin < ReportBuilder
      def report_name
        "General plugin health"
      end

      def report_fields
        ["Plugin name", "Problem description"]
      end

      def collect
      end

      def add(*args)
        report.add(*args)
      end

      def other_summary
        "There were problems defining plugins"
      end

      def other_advice
        <<-EOA
        The plugins above had unrecoverable issues while being defined. They
        should be fixed, or not included during generation.
        EOA
      end
    end
  end
end
