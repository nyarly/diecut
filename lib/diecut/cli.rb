require 'thor'
require 'diecut'
require 'diecut/mill'

module Diecut
  module Cli
    class KindGroup < Thor::Group
      def self.subclass_for(kind, mediator = nil, example_ui = nil)
        mediator ||= Diecut.mediator(kind)
        example_ui ||= mediator.build_example_ui

        Class.new(self) do
          def self.kind
            @kind
          end

          mediator.plugins.each do |plugin|
            class_option "with-#{plugin.name}", :default => plugin.default_active?
          end

          setup_subclass(mediator, example_ui)
        end.tap do |klass|
          klass.instance_variable_set("@kind", kind)
        end
      end

      def self.setup_subclass(mediator, example_ui)
      end
    end

    class Generate < KindGroup
      include Thor::Actions

      def self.setup_subclass(mediator, example_ui)
        example_ui.field_names.each do |field|
          class_option(field, {
            :desc     => example_ui.description(field) || field,
            :required => example_ui.required?(field),
            :default  => example_ui.default_for(field)
          })
        end
      end

      def files
        self.destination_root = target_dir

        mill = Mill.new(self.class.kind)
        mill.activate_plugins {|name| options["with-#{name}"] }

        ui = mill.user_interface
        options.delete_if{|_, value| value.nil?}
        ui.from_hash(options)

        mill.churn(ui) do |path, contents|
          create_file(path, contents)
        end
      end
    end

    class TargetedGenerate < Generate
      argument :target_dir, :required => true, :type => :string, :banner => "The directory to use as the root of generated output"
    end

    class Lint < KindGroup
      class_option :all_on, :default => false, :type => :boolean

      def lint
        require 'diecut/linter'
        mill = Mill.new(self.class.kind)
        if options["all_on"]
          mill.activate_plugins{ true }
        else
          mill.activate_plugins{|name| options["with-#{name}"] }
        end

        puts Linter.new(mill).report
      end
    end
  end

  class CommandLine < Thor
    def self.build_kind_subcommand(plugin_kind)
      mediator = Diecut.mediator(plugin_kind)
      example_ui = mediator.build_example_ui

      Class.new(Thor) do
        gen = Cli::TargetedGenerate.subclass_for(plugin_kind, mediator, example_ui)
        method_options(gen.class_options)
        register gen,
          "generate", "generate TARGET", "Generate #{plugin_kind} output"

        lint = Cli::Lint.subclass_for(plugin_kind, mediator, example_ui)
        method_options(lint.class_options)
        register lint,
          "lint", "lint", "Check well-formed-ness of #{plugin_kind} code generators"
      end
    end

    def self.add_kind(kind)
      desc "#{kind}", "Commands related to templating for #{kind}"
      kind_class = build_kind_subcommand(kind)
      const_set(kind.sub(/\A./){|match| match.upcase }, kind_class)
      subcommand kind, kind_class
    end
  end
end
