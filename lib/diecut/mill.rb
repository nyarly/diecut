require 'valise'
require 'diecut/template-set'

module Diecut
  class Mill
    def initialize
      @templates = nil
    end

    attr_accessor :valise

    def templates
      @templates ||= TemplateSet.new
    end

    def load_files
      valise.filter('**', %i[extended dotmatch]).files do |file|
        templates.add(file.rel_path.to_s, file.contents)
      end
    end

    def prepare
      load_files
      templates.prepare
    end

    def results(&block)
      templates.results(&block)
    end
  end
end
