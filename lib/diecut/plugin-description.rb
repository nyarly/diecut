require 'diecut/errors'

module Diecut
  module CallerLocationsPolyfill
    unless Kernel.instance_method(:caller_locations)
      FakeLocation = Struct.new(:absolute_path, :lineno, :label)
      LINE_RE = %r[(?<absolute_path>[^:]):(?<lineno>\d+):(?:in `(?<label>[^'])')?]
      # covers exactly the use cases we need
      def caller_locations(range, length=nil)
        caller[range.begin+1..range.end+1].map do |line|
          if m = LINE_RE.match(line)
            FakeLocation.new(m.named_captures.values_at("absolute_path", "lineno", "label"))
          end
        end
      end
    end
  end

  class PluginDescription
    include CallerLocationsPolyfill
    NO_VALUE = Object.new.freeze

    KindStem = Struct.new(:kind, :stem, :declared_at)

    class ContextDefault < Struct.new(:context_path, :value, :block)
      def simple?
        value != NO_VALUE
      end

      def compute_value(context)
        block.call(context)
      end
    end

    class Option
      def initialize(name)
        @name = name
        @default_value = NO_VALUE
      end
      attr_reader :name, :description, :context_path, :default_value

      def has_default?
        default_value != NO_VALUE
      end

      def has_context_path?
        !context_path.nil?
      end

      def description(desc = NO_VALUE)
        if desc == NO_VALUE
          return @description
        else
          @description = desc
        end
      end

      def goes_to(*context_path)
        if context_path.length == 1
          context_path =
            case context_path.first
            when Array
              context_path.first
            when /.+\..+/ # has an embedded .
              context_path.first.split('.')
            else
              context_path
            end
        end

        @context_path = context_path
      end

      def default(value)
        @default_value = value
      end
    end

    def initialize(name)
      @name = name
      @default_activated = true
      @context_defaults = []
      @options = []
      @resolve_block = nil
      @kind_stems = {}
    end
    attr_reader :default_activated, :name, :context_defaults, :options, :resolve_block

    def has_kind?(kind)
      @kind_stems.key?(kind)
    end

    def for_kind(kind, templates = nil, stem = nil)
      @kind_stems[kind] = KindStem.new(kind, stem || [], templates || File.dirname(caller_locations(1..1).first.absolute_path))
    end

    def default_off
      @default_activated = false
    end

    def default_on
      @default_activated = true
    end

    def default(context_path, value = NO_VALUE, &block)
      if value != NO_VALUE and not block.nil?
        raise InvalidPlugin, "Default on #{name.inspect} both has a simple default value (#{value}) and a dynamic block value, which isn't allowed."
      end
      @context_defaults << ContextDefault.new(context_path, value, block)
    end

    def option(name)
      option = Option.new(name)
      yield option
      @options << option
      return option
    end

    def resolve(&block)
      @resolve_block = block
    end

    def apply_resolve(ui, context)
      @resolve_block.call(ui, context)
    end
  end
end
