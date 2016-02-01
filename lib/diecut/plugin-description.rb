require 'diecut/errors'
require 'diecut/caller-locations-polyfill'
require 'diecut/plugin-description/context-default'
require 'diecut/plugin-description/option'

module Diecut
  class PluginDescription
    include CallerLocationsPolyfill
    NO_VALUE = Object.new.freeze

    KindStem = Struct.new(:kind, :stem, :template_dir)

    def initialize(name, source_path)
      @name = name
      @source_path = source_path
      @default_activated = true
      @context_defaults = []
      @options = []
      @resolve_block = nil
      @kind_stems = {}
    end
    attr_reader :default_activated, :name, :source_path, :context_defaults,
      :options, :resolve_block

    def kinds
      @kind_stems.keys
    end

    def stem_for(kind)
      @kind_stems.fetch(kind)
    end

    def has_kind?(kind)
      @kind_stems.key?(kind)
    end

    def default_active?
      @default_activated
    end

    def apply_resolve(ui, context)
      @resolve_block.call(ui, context)
    end

    # Attaches this plugin to a particular kind of diecut generator. Can be
    # called multiple times in order to reuse the plugin.
    #
    # @param kind [String, Symbol]
    #   The kind of generator to register the plugin to
    # @param templates [String]
    #   The directory of templates that the plugin adds to the generation
    #   process. Relative paths are resolved from the directory the plugin is
    #   being defined in. If omitted (or nil) defaults to "templates"
    # @param stem [Array(String), String]
    #   A prefix for the templates directory when it's used for this kind of
    #   generator. By default, this will be [kind], which is what you'll
    #   probably want in a gem plugin. For local plugins, you probably want to
    #   have directories per kind, and set this to []
    #
    # For instance, you might set up a plugin for Rails that also works in Xing
    # projects that use Rails for a backend
    #
    # @example Install for Rails and Xing
    #   plugin.for_kind(:rails)
    #   plugin.for_kind(:xing, nil, "xing/backend")
    #
    #
    def for_kind(kind, templates = nil, stem = nil)
      stem ||= [kind]
      templates ||= "templates"
      templates = File.expand_path(templates, File.dirname(caller_locations(1..1).first.absolute_path))
      @kind_stems[kind] = KindStem.new(kind, stem, templates)
    end

    # Force this plugin to be enabled to be used. Good for optional features.
    def default_off
      @default_activated = false
    end

    # Make this plugin part of the generation process by default. The is the
    # default behavior anyway, provided for consistency.
    def default_on
      @default_activated = true
    end

    # Set a default value for a field in the templating context.
    #
    # @param context_path [String, Array]
    #   Either an array of strings or a dotted string (e.g.
    #   "deeply.nested.value") that describes a path into the templating
    #   context to give a default value to.
    #
    # @param value
    #   A simple default value, which will be used verbatim (n.b. it will be
    #   cloned if appropriate, so you can use [] for an array).
    #
    # @yieldreturn
    #   A computed default value. The block will be called when the context is
    #   set up. You cannot use both a simple value and a computed value.
    #
    # @example
    #   plugin.default("built_at"){ Time.now }
    #   plugin.default("author", "Judson")
    def default(context_path, value = NO_VALUE, &block)
      if value != NO_VALUE and not block.nil?
        raise InvalidPlugin, "Default on #{name.inspect} both has a simple default value (#{value}) and a dynamic block value, which isn't allowed."
      end
      @context_defaults << ContextDefault.new(context_path, value, block)
    end

    # Define an option to provide to the user interface.
    # @param name [String,Symbol]
    #   The name for the option, as it'll be provided to the user.
    # @yieldparam option [Option]
    #   The option description object
    def option(name)
      name = name.to_sym
      option = Option.new(name)
      yield option
      @options << option
      return option
    end

    # The resolve block provides the loophole to allow complete configuration
    # of the rendering context. The last thing that happens before files are
    # generated is that all the plugin resolves are run, so that e.g. values
    # can be calculated from other values. It's very difficult to analyze
    # resolve blocks, however: use them as sparingly as possible.
    #
    # @yeildparam ui [UIContext]
    #   the values supplied by the user to satisfy options
    # @yeildparam context [Configurable]
    #   the configured rendering context
    def resolve(&block)
      @resolve_block = block
    end
  end
end
