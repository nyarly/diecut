require 'diecut/mediator'
require 'diecut/plugin-description'

module Diecut
  class << self
    def clear_plugins
      plugins.clear
    end

    def plugins
      @plugins ||= []
    end

    def plugin(name)
      desc = PluginDescription.new(name)
      yield(desc)
      plugins << desc
      return desc
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
