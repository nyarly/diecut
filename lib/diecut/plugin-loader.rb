require 'tsort'
require 'rubygems/specification'
require 'diecut/plugin-description'

module Diecut
  class PluginLoader
    include TSort

    NO_VALUE = Object.new.freeze

    class GemPlugin < Struct.new(:gem, :path)
      def gem?
        gem != NO_VALUE
      end
    end

    def initialize
      @sources = {}
      @local_sources = []
      @by_gem_name = Hash.new{|h,k| h[k] = []}
      @plugins = []
    end
    attr_reader :plugins
    attr_accessor :local_valise

    def local_valise
      @local_valise ||= Valise::Set.define do
        ro '.diecut'
        ro '~/.config/diecut'
        ro '/usr/share/diecut'
        ro '/etc/diecut'
      end
    end

    def latest_specs(prerelease)
      Gem::Specification.latest_specs(prerelease)
    end

    def require_plugin(path)
      require path
    end

    PLUGIN_FILENAME = 'diecut_plugin.rb'
    def discover(prerelease)
      latest_specs(prerelease).map do |spec|
        spec.matches_for_glob(PLUGIN_FILENAME).map do |match|
          from_gem(spec, match)
        end
      end
      local_valise.get(PLUGIN_FILENAME).present.map(&:full_path).each do |path|
        from_local(path)
      end
    end

    def from_gem(spec, path)
      plugin = GemPlugin.new(spec, path)

      @sources[path] = plugin
      spec.dependencies.map(&:name).each do |depname|
        @by_gem_name[depname] << plugin
      end
    end

    def from_local(path)
      source = GemPlugin.new(NO_VALUE, path)
      @sources[path] = source
      @local_sources << source
    end

    def tsort_each_node(&block)
      @sources.each_value(&block)
    end

    def tsort_each_child(node)
      if node.gem?
        @by_gem_name[node.gem.name].each do |depplugin|
          yield depplugin
        end
        @local_sources.each do |local|
          yield local
        end
      else
        @local_sources.drop_while do |src|
          src != node
        end.drop(1).each do |node|
          yield(node)
        end
      end
    end

    def component_sort
      unless block_given?
        return enum_for(:component_sort)
      end
      child_idxs = {}
      strongly_connected_components.each_with_index do |component, idx|
        component.sort_by{|node| child_idxs.fetch(node, -1) }.each do |comp|
          yield(comp)
        end

        component.each do |comp|
          tsort_each_child(comp) do |child|
            child_idxs[child] = idx
          end
        end
      end
    end

    def each_path
      component_sort.reverse_each do |source|
        yield source.path
      end
    end

    # Can a chain of "is after" arrows be walked from 'from' to 'to'.
    # The rules are:
    # A plugin defined by a gem that depends on another gem "is after" the
    # plugin defined in the latter gem.
    # A plugin defined in a local config file is after "more general" local
    # files (project config is after personal is after system).
    # All local plugins are after all gem plugins
    #
    # The rationale for these rules is that decisions made later in time have
    # more information and that decisions made closer to the problem know the
    # problem domain better.
    #
    def strict_sequence?(to, from)
      from_source = @sources[from.source_path]
      to_source = @sources[to.source_path]

      case [from_source.gem?, to_source.gem?]
      when [true, true]
        dep_path?(from_source.gem, to_source.gem)
      when [true, false]
        false
      when [false, true]
        true
      when [false, false]
        @local_sources.index_of(from.source_path) <= @local_sources.index_of(to.source_path)
      end
    end

    def dep_path(from_gem, to_gem)
      # potential to optimize this: build a map of reachablility and test
      # against that.
      closed = {}
      open = [from_gem]
      until open.empty?
        current = open.shift
        return true if current == to_gem
        closed[current] = true
        open += @by_gem_name[current].select{|gem| !closed.has_key?(gem)}
      end
      return false
    end

    def load_plugins(prerelease = false)
      discover(prerelease)
      each_path do |path|
        require_plugin(path)
      end
    end

    def choose_source(locations)
      locations.each do |loc|
        path = loc.absolute_path
        if @sources.has_key?(path)
          return path
        end
      end
      raise "Couldn't find source of plugin..."
    end

    def add_plugin_desc(desc)
      plugins << desc
    end

    def describe_plugin(name)
      source_path = choose_source(caller_locations)
      desc = PluginDescription.new(name, source_path)
      yield(desc)
      add_plugin_desc(desc)
      return desc
    end

  end
end
