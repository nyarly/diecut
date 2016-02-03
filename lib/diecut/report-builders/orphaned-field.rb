module Diecut
  module ReportBuilders
    class OrphanedField < ReportBuilder
      register

      def report_name
        "Template fields all have settings"
      end

      def report_fields
        ["Output field", "Source file"]
      end

      def collect
        context_class = mill.context_class

        required_fields = {}

        context_class.field_names.each do |field_name|
          if context_class.field_metadata(field_name).is?(:required)
            required_fields[field_name.to_s] = []
          end
        end

        each_template do |name, template|
          template.reduced.leaf_fields.each do |field|
            field = field.join(".")
            if required_fields.has_key?(field)
              required_fields[field] << template.path
            end
          end
        end

        each_option do |option, plugin|
          next unless option.has_context_path?
          field = option.context_path.join(".")
          required_fields.delete(field)
        end

        required_fields.each do |name, targets|
          targets.each do |target|
            report.add(name, target)
          end
        end
      end

      def report_status
        report.empty? ? "OK" : "WARN"
      end


      def other_advice
        <<-EOA
        These fields might not receive a value during generation, which will
        raise an error at use time.

        It's possible these fields are set in a resolve block in one of the
        plugins - Diecut can't check for that yet.
        EOA
      end
    end
  end
end
