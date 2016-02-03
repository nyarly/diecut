require 'diecut/errors'
require 'diecut/report'
require 'diecut/report-builders/missing-context-field'
require 'diecut/report-builders/unused-default'
require 'diecut/report-builders/invalid-plugin'
require 'diecut/report-builders/exception-report'

module Diecut
  module ErrorHandling
    class Reporter < Base
      def initialize(mill)
        @mill = mill
      end

      def missing_context_field_report
        @missing_context_field_report ||= ReportBuilders::MissingContextField.new(@mill)
      end

      def unused_default_report
        @unused_default_report ||= ReportBuilders::UnusedDefault.new(@mill)
      end

      def invalid_plugin_report
        @invalid_plugin_report ||= ReportBuilders::InvalidPlugin.new(@mill)
      end

      def exception_report
        @exception_report ||= ReportBuilders::Exceptions.new(@mill)
      end

      def missing_context_field(plugin_name, option_name, context_path)
        missing_context_field_report.add(option_name, context_path, plugin_name)
      end

      def unused_default(plugin_name, context_path)
        unused_default_report.add(context_path, plugin_name)
      end

      def invalid_plugin(name, context_path, value)
        invalid_plugin_report.add(name, context_path, value)
      end

      def handle_exception(ex)
        raise unless ex.is_a? Diecut::Error
        exception_report.add(ex.class.name, ex.message, (ex.backtrace || [""]).first)
      end

      def reports
        [
          missing_context_field_report.go,
          unused_default_report.go,
          invalid_plugin_report.go,
          exception_report.go
        ]
      end
    end
  end
end
