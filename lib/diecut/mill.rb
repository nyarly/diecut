require 'valise'
require 'diecut/template-set'

module Diecut
  class Mill
    def initialize(kind)
      @kind = kind
      @templates = nil
    end
    attr_reader :kind

    def valise
      @valise ||= Valise::Set.define do
        ro "~/.config/diecut"
      end
    end
    attr_writer :valise

    # XXX This would be nice, but needs plugins to work well
    def kinds
    end

    def templates
      @templates ||= TemplateSet.new
    end

    def load_files
      kind_valise = valise.sub_set(kind)

      puts "\n#{__FILE__}:#{__LINE__} => #{kind_valise.method(:files).source_location.inspect}"
      kind_valise.filter('**', %i[extended dotmatch]).files do |file|
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
