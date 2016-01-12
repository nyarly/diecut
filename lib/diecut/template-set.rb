require 'tsort'
require 'diecut/template'
require 'diecut/mustache'
require 'diecut/configurable'

module Diecut
  class TemplateSet
    include TSort

    def initialize
      @templates = {}
      @path_templates = {}
      @breaking_cycles = {}
      @partials = {}
      @context_class = nil
      @context = nil
      @renderer = nil
    end
    attr_reader :partials

    def add(path, contents)
      template = Diecut::Template.new(path, contents)
      @templates[path] = template
      @path_templates[path] = Diecut::Template.new("path for " + path, path)
      template.partials.each do |name, _|
        @partials[name] = template
      end
    end

    def context_class
      @context_class ||= Class.new(Configurable)
    end

    def context
      @context ||= context_class.new
    end

    def is_partial?(tmpl)
      @partials.has_key?(tmpl.path)
    end

    def tsort_each_node(&block)
      @breaking_cycles.clear
      @templates.each_value(&block)
    end

    def tsort_each_child(node)
      node.partials.each do |name, _|
        unless @breaking_cycles[name]
          @breaking_cycles[name] = true
          yield @templates[name]
        end
      end
    end

    def prepare
      associate_partials
      build_context
    end

    def renderer
      @renderer ||= Mustache.new.tap do |mustache|
        mustache.partials_hash = partials
      end
    end

    def results
      context.check_required

      tsort_each do |template|
        next if is_partial?(template)

        path = @path_templates[template.path]
        context.copy_settings_to(template.context)
        context.copy_settings_to(path.context)

        yield path.render(renderer), template.render(renderer)
      end
    end

    def associate_partials
      partials = []
      tsort_each do |template|
        partials.each do |partial|
          template.partial_context(partial)
        end
        if is_partial?(template)
          partials << template
        end
      end
    end

    def build_context
      tsort_each do |template|
        context_class.absorb_context(context_class)
      end
      @path_templates.each_value do |template|
        context_class.absorb_context(template.context_class)
      end
      context.setup_defaults
    end
  end
end
