require 'valise'
require 'diecut'
require 'diecut/errors'
require 'diecut/template-set'

module Diecut
  class Mill
    def initialize(kind)
      @kind = kind
    end
    attr_reader :kind
    attr_writer :valise, :mediator, :templates, :issue_handler

    def mediator
      @mediator ||= Diecut.mediator(kind)
    end

    def templates
      @templates ||= TemplateSet.new
    end

    def activate_plugins
      mediator.plugins.map(&:name).each do |name|
        if yield(name)
          mediator.activate(name)
        else
          mediator.deactivate(name)
        end
      end
    end

    def valise
      @valise ||=
        begin
          stems = mediator.activated_plugins.map do |plugin|
            plugin.stem_for(kind)
          end
          Valise::Set.define do
            stems.each do |stem|
              ro stem.template_dir
            end
          end
        end
    end

    def load_files
      valise.filter('**', %i[extended dotmatch]).files do |file|
        templates.add(file.rel_path.to_s, file.contents)
      end
    end

    def context_class
      templates.context_class
    end

    def ui_class
      mediator.build_ui_class(context_class)
    end

    def user_interface
      load_files
      templates.prepare

      ui_class.new
    end

    def churn(ui)
      templates.context = mediator.apply_user_input(ui, templates.context_class)
      templates.results do |path, contents|
        yield(path, contents)
      end
    end
  end
end
