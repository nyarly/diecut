require 'tsort'
require 'rubygems/specification'

module Diecut
  class GemPlugin < Struct.new(:gem, :path)
  end

  class PluginLoader
    include TSort

    def initialize
      @gem_sources = []
      @local_sources = []
      @by_gem_name = Hash.new{|h,k| h[k] = []}
    end

    def discover(prerelease)
      Gem::Specification.latest_specs(prerelease).map do |spec|
        spec.matches_for_glob('diecut_plugin').map do |match|
          puts "\n#{__FILE__}:#{__LINE__} => #{match.inspect}"
          from_gem(spec, match)
        end
      end
      %w(~/.config/diecut/diecut_plugin.rb).each do |path|
        path = File.expand_path(path)
        if File.readable?(path)
          from_local(path)
        end
      end
    end

    def from_gem(spec, path)
      plugin = GemPlugin.new(spec, path)

      @gem_sources << plugin
      spec.dependencies.map(&:name).each do |depname|
        @by_gem_name[depname] << plugin
      end
    end

    def from_local(path)
      @local_sources << GemPlugin.new(nil, path)
    end

    def tsort_each_node(&block)
      @gem_sources.each(&block)
      @local_sources.each(&block)
    end

    def tsort_each_child(node)
      if node.gem.nil?
        @local_sources.drop_while do |src|
          src == node
        end.drop(1).each do |node|
          yield(node)
        end
      else
        @by_gem_name[node.gem.name].each do |depplugin|
          yield depplugin
        end
        @local_sources.each do |local|
          yield local
        end
      end
    end

    def each_path
      tsort_each do |source|
        yield source.path
      end
    end
  end
end
