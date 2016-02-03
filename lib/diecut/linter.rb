require 'diecut/report-builder'

require 'diecut/report-builders/template-list'
require 'diecut/report-builders/overridden-context-defaults'
require 'diecut/report-builders/option-collision'
require 'diecut/report-builders/orphaned-field'

module Diecut

  class Linter
    def initialize(mill)
      @mill = mill
    end
    attr_reader :mill

    def report
      @ui = mill.user_interface

      reports = ReportBuilder.all_kinds.map do |kind|
        kind.new(mill).go
      end
      if Diecut.issue_handler.respond_to?(:reports)
        reports += Diecut.issue_handler.reports
      end
      formatter = ReportFormatter.new( reports)
      formatter.to_s
    end

    # Needed:
    # Overridden option defaults (without plugin dep)
    # Option with default, context with default (w/o PD)

    def unindent(text)
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
  end
end
