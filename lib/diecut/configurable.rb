require 'calibrate'
module Diecut
  class Configurable
    include Calibrate::Configurable
    module ClassMethods
      def absorb_context(from)
        from.field_names.each do |name|
          from_value = from.field_metadata(name).default_value
          into_metadata = field_metadata(name)
          if into_metadata.nil?
            if from_value.is_a?(Class) and from_value < Calibrate::Configurable
              nested = Class.new(Configurable)
              setting(name, nested)
              nested.absorb_context(from_value)
            else
              setting(name, from_value)
            end
            next
          end
          into_value = into_metadata.default_value
          if into_value.is_a?(Class) and into_value < Calibrate::Configurable
            if from_value.is_a?(Class) and from_value < Calibrate::Configurable
              into_value.absorb_context(from_value)
            else
              raise "Field clash: #{name.inspect} is already a complex value, but a simple value in absorbed configurable"
            end
          else
            unless from_value.is_a?(Class) and from_value < Calibrate::Configurable
              # Noop - maybe should compare the default values? - should always
              # be nil right now...
            else
              raise "Field clash: #{name.inspect} is already a simple value, but a complex value on the absorbed configurable"
            end
          end
        end
      end

      def walk_path(field_path)
        first, *rest = *field_path

        segment = PathSegment.new(self, first.to_sym)
        if rest.empty?
          [segment]
        else
          [segment] + segment.nested.walk_path(rest)
        end
      end

      def build_setting(field, is_section = false)
        nested = walk_path(field).last.nested

        if is_section
          nested.setting(field.last, Class.new(Configurable))
        else
          nested.setting(field.last)
        end
      end
    end
    extend ClassMethods

    def walk_path(field_path)
      first, *rest = *field_path

      segment = InstanceSegment.new(self, first.to_sym)
      if rest.empty?
        [segment]
      else
        [segment] + segment.value.walk_path(rest)
      end

    end

    class InstanceSegment < ::Struct.new(:instance, :name)
      def metadata
        @metadata ||= instance.class.field_metadata(name)
      end

      def value
        metadata.value_on(instance)
      end

      def value=(value)
        instance.__send__(metadata.writer_method, value)
      end

    end

    class PathSegment < ::Struct.new(:klass, :name)
      def metadata
        @metadata ||= klass.field_metadata(name)
      end

      def nested
        @nested ||=
          begin
            if metadata.nil?
              Class.new(Configurable).tap{|nested| klass.setting(name, nested) }
            else
              metadata.default_value
            end
          end
      end
    end
  end
end
