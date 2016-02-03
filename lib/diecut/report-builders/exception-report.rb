require 'diecut/report-builder'

module Diecut
  module ReportBuilders
    class Exceptions < ReportBuilder
      def report_name
        "Exceptions raised during definition"
      end

      def report_fields
        ["Exception class", "message", "source line"]
      end

      def collect
      end

      def add(*args)
        report.add(*args)
      end

      def fail_summary
        "Exceptions were raised during the kind definition process"
      end

      def other_advice
        <<-EOA
        Exceptions were raised while defining plugins for generation. Those need to be fixed.
        EOA
      end
    end
  end
end
