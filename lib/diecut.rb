require 'diecut/mediator'
require 'diecut/plugin-description'
require 'diecut/plugin-loader'
require 'diecut/errors'

module Diecut
  class << self
    def plugin_loader
      @plugin_loader ||= PluginLoader.new
    end

    def plugin_loader=(loader)
      @plugin_loader = loader
    end

    def clear_plugins
      @plugin_loader = nil
    end

    def load_plugins(prerelease = false)
      plugin_loader.load_plugins(prerelease)
    end

    def plugins
      plugin_loader.plugins
    end

    def issue_handler
      @issue_handler ||= ErrorHandling::AllWarn.new
    end
    attr_writer :issue_handler

    # Used in a `diecut_plugin.rb` file (either in the `lib/` of a gem, or at
    # the local `~/.config/diecut/diecut_plugin.rb` to register a new plugin.
    #
    # @param name [String, Symbol]
    #   Names the plugin so that it can be toggled  later
    #
    # @yieldparam description [PluginDescription]
    #   The description object to configure the plugin with.
    def plugin(name, &block)
      plugin_loader.describe_plugin(name, &block)
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
