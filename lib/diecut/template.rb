require 'diecut/configurable'
require 'diecut/template-context'
require 'diecut/template-reducer'

module Diecut
  class Template
    def initialize(path, template_string)
      @path = path
      @template_string = template_string
      @reduced = nil
      @context_class = nil
      @context = nil
    end

    attr_reader :path, :template_string

    def partial_context(other)
      reduced.partials.each do |path, nesting|
        next unless path == other.path
        add_subcontext(nesting, other.context_class)
      end
    end

    def add_subcontext(nesting, other)
      other.field_names.each do |field|
        context_class.build_setting(nesting + [field])
      end
    end

    def context_class
      @context_class ||= build_context_class
    end

    def reduced
      @reduced ||= TemplateReducer.new(Mustache::Parser.new.compile(template_string))
    end

    def partials
      reduced.partials
    end

    def build_context_class
      klass = Class.new(Configurable)
      TemplateContext.add(path, klass)

      reduced.leaf_fields.each do |field|
        klass.build_setting(field, reduced.sections.include?(field))
      end
      klass
    end
    def context
      @context ||= context_class.new
    end

    def render(renderer)
      renderer.render(template_string, context.to_hash)
    end
  end
end
