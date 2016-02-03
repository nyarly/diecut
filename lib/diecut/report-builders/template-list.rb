require 'diecut/report-builder'

module Diecut
  class TemplateListBuilder < ReportBuilder
    register

    def report_name
      "Templates included"
    end

    def report_fields
      ["Template path"]
    end

    def collect
      each_template do |name, template|
        report.add(template.path)
      end
    end

    def report_status
      report.empty? ? 'FAIL' : 'OK'
    end

    def fail_summary
      report.summary = "No templates will render"
    end

    def fail_advice
      (<<-EOA)
      No plugin provides any templates. This is probably simple misconfiguration a plugin, or an important plugin has been omitted.

      Plugins: #{mill.mediator.activated_plugins.map(&:name)}
      Plugin template paths: #{mill.valise.to_s}
      EOA
    end
  end
end
