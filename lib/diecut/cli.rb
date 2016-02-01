require 'thor'
require 'diecut'
require 'diecut/mill'

module Diecut
  class KindCli < Thor
    include Thor::Actions

    desc "generate TARGET", "Generate code"
    def generate(target_dir)
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

    method_option :all_on => false
    desc "lint", "Check well-formed-ness of code generators"
    def lint
      require 'diecut/linter'
      mill = Mill.new(self.class.kind)
      if options["all_on"]
        mill.activate_plugins{ true }
      else
        mill.activate_plugins {|name| options["with-#{name}"] }
      end

      puts Linter.new(mill).report
    end
  end

  class CommandLine < Thor
    def self.build_kind_subcommand(plugin_kind)
      mediator = Diecut.mediator(plugin_kind)
      example_ui = mediator.build_example_ui

      klass = Class.new(KindCli) do
        class << self
          def kind(value = nil)
            if @kind.nil?
              @kind = value
            end
            @kind
          end
        end

        mediator.plugins.each do |plugin|
          class_option "with-#{plugin.name}", :default => plugin.default_active?
        end

        example_ui.field_names.each do |field|
          method_option(field, {:for => :generate, :desc => example_ui.description(field) || field,
            :required => example_ui.required?(field), :default => example_ui.default_for(field)})
        end
      end

      klass.kind(plugin_kind)

      klass
    end

    def self.add_kind(kind)
      desc "#{kind}", "Commands related to templating for #{kind}"
      kind_class = build_kind_subcommand(kind)
      const_set(kind.sub(/\A./){|match| match.upcase }, kind_class)
      subcommand kind, kind_class
    end
  end
end
