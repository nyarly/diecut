require 'diecut/mediator'
require 'diecut/plugin-description'
require 'diecut/plugin-loader'

module Diecut
  class << self
    def load_plugins(prerelease = false)
      loader = PluginLoader.new
      loader.discover(prerelease)
      loader.each_path do |path|
        require path
      end
    end

    def clear_plugins
      plugins.clear
    end

    def plugins
      @plugins ||= []
    end

    # Used in a `diecut_plugin.rb` file (either in the `lib/` of a gem, or at
    # the local `~/.config/diecut/diecut_plugin.rb` to register a new plugin.
    #
    # @param name [String, Symbol]
    #   Names the plugin so that it can be toggled  later
    #
    # @yieldparam description [PluginDescription]
    #   The description object to configure the plugin with.
    def plugin(name)
      desc = PluginDescription.new(name)
      yield(desc)
      plugins << desc
      return desc
    end

    def kinds
      plugins.reduce([]) do |list, plugin|
        list + plugin.kinds
      end.uniq
    end

    def mediator(kind)
      Mediator.new.tap do |med|
        plugins.each do |plug|
          next unless plug.has_kind?(kind)
          med.add_plugin(plug)
        end
      end
    end
  end
end
