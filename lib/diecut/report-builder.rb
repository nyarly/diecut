require 'diecut/report'

module Diecut
  class ReportBuilder
    def self.all_kinds
      @all_kinds ||= []
    end

    def self.register
      ReportBuilder.all_kinds << self
    end

    def initialize(mill)
      @mill = mill
    end
    attr_reader :mill

    def unindent(text)
      return if text.nil?
      indent = text.scan(/(^[ \t]*)\S/).map{|cap| cap.first}.max_by(&:length)
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

    def each_template
      mill.templates.templates.each do |name, template|
        yield name, template
      end
    end

    def report
      @report ||= build_report
    end

    def build_report
      Report.new(report_name, report_fields)
    end

    def strict_sequence?(first, second)
      return false if first == second
      Diecut.plugin_loader.strict_sequence?(first, second)
    end

    def go
      collect
      review
      report
    end

    def report_status
      report.empty? ? 'OK' : 'FAIL'
    end

    def pass_summary
      nil
    end

    def fail_summary
      nil
    end

    def other_summary
      nil
    end

    def pass_advice
      nil
    end

    def fail_advice
      nil
    end

    def other_advice
      nil
    end

    def review
      report.status = report_status.to_s.upcase
      case report.status
      when "OK", "PASS"
        report.summary = pass_summary
        report.advice = unindent(pass_advice)
      when 'FAIL'
        report.summary = fail_summary
        report.advice = unindent(fail_advice)
      else
        report.summary = other_summary
        report.advice = unindent(other_advice)
      end
    end
  end
end
