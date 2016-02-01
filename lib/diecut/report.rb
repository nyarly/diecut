require 'paint'
require 'diecut/mustache'

module Diecut
  #Adopted gratefully from Xavier Shay's Cane
  class ReportFormatter
    def initialize(reports)
      @reports = reports
    end
    attr_reader :reports

    def rejection_fields
      %i(file_and_line label value)
    end

    def template
      (<<-EOT).gsub(/^      /, '')
      {{#reports}}{{#status_color}}{{name}}: {{status}} {{#length}} {{length}}{{/length}}
      {{/status_color}}
      {{#summary}}{{summary}}
      {{/summary}}{{^empty  }}{{#headers}}{{it}}    {{/headers}}
      {{/empty  }}{{#rejects}} {{#reject }}{{it}}    {{/reject}}
      {{/rejects}}{{#advice}}
      {{advice}}
      {{/advice}}
      {{/reports}}
      {{#status_color}}Total QA report items: {{total_items}}
      Total QA failing reports: {{total_fails}}
      {{/status_color}}
      EOT
    end

    def to_s(widths=nil)
      renderer = Mustache.new

      # require 'pp'; puts "\n#{__FILE__}:#{__LINE__} => {context(renderer).pretty_inspect}"
      renderer.render(template, context(renderer))
    end

    def passed?
      fail_count == 0
    end

    def fail_count
      reports.inject(0){|sum, report| sum + (report.passed ? 0 : 1)}
    end

    def context(renderer)
      bad_color = proc{|text,render| Paint[renderer.render(text), :red]}
      good_color =  proc{|text,render| Paint[renderer.render(text), :green]}
      warn_color = proc{|text,render| Paint[renderer.render(text), :yellow]}

      context = {
        reports: reports.map(&:context),
        passed: passed?,
        total_items: reports.inject(0){|sum, report| sum + report.length},
        total_fails: fail_count,
        status_color: passed? ? good_color : bad_color
      }
      context[:reports].each do |report|
        report[:status_color] =
          case report[:status]
          when /ok/i
            good_color
          when /fail/i
            bad_color
          else
            warn_color
          end
      end
      context
    end
  end

  class Report
    def initialize(name, column_headers)
      @name = name
      @column_headers = column_headers
      @rejects = []
      @status = "OK"
      @passed = true
      @summary = ""
      @summary_counts = true
    end
    attr_reader :name, :column_headers, :rejects
    attr_accessor :summary, :passed, :summary_count, :advice, :status

    def add(*args)
      @rejects << args
    end

    def fail(summary)
      @passed = false
      @status = "FAIL"
      @summary = summary
    end

    def length
      @rejects.length
    end
    alias count length

    def empty?
      @rejects.empty?
    end

    def column_widths
      column_headers.map.with_index do |header, idx|
        (@rejects.map{|reject| reject[idx]} + [header]).map{|field|
          field.to_s.length
        }.max
      end
    end

    def sized(array, widths)
      array.take(widths.length).zip(widths).map{|item, width| { it: item.to_s.ljust(width)}}
    end

    def context
      widths = column_widths
      {
        empty: empty?,
        passing: passed,
        status: status,
        name: name,
        length: summary_count,
        summary: summary,
        advice: advice,
        headers: sized(column_headers, widths),
        rejects: rejects.map do |reject|
          {reject: sized(reject, widths)}
        end
      }
    end
  end
end
