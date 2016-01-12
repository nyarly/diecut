require 'calibrate'
module Diecut
  class Configurable
    include Calibrate::Configurable

    def self.absorb_context(from)
      from.field_names.each do |name|
        puts "\n#{__FILE__}:#{__LINE__} => #{name.inspect}"
        from_value = from.field_metadata(name).default_value
        into_metadata = field_metadata(name)
        if into_metadata.nil?
          if from_value.is_a?(Class) and from_value < Calibrate::Configurable
            nested = Class.new(Configurable)
            setting(name, nested)
            absorb_context(from_value, nested)
          else
            setting(name, from_value)
          end
          next
        end
        into_value = into_metadata.default_value
        if into_value.is_a?(Class) and into_value < Calibrate::Configurable
          if from_value.is_a?(Class) and from_value < Calibrate::Configurable
            absorb_context(from_value, into_value)
          else
            raise "Field clash: #{name} is both a simple and complex value. [too cryptic - sorry]"
          end
        else
          unless from_value.is_a?(Class) and from_value < Calibrate::Configurable
            absorb_context(from_value, into_value)
          else
            raise "Field clash: #{name} is both a simple and complex value. [too cryptic - sorry]"
          end
        end
      end
    end
  end
end
