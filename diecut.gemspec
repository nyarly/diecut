Gem::Specification.new do |spec|
  spec.name		= "diecut"
  spec.version		= "0.0.5"
  author_list = {
    "Judson Lester" => 'nyarly@gmail.com'
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Code generation support tools"
  spec.description	= <<-EndDescription
  Diecut is a tool for supporting the process of writing code generation. It provides
  linting, a general purpose command line generator, discovery of templated values, and
  composed generation.
  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://nyarly.github.com/#{spec.name.downcase}"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    lib/diecut/context-handler.rb
    lib/diecut/plugin-description/context-default.rb
    lib/diecut/plugin-description/option.rb
    lib/diecut/caller-locations-polyfill.rb
    lib/diecut/report.rb
    lib/diecut/mill.rb
    lib/diecut/template.rb
    lib/diecut/cli.rb
    lib/diecut/ui-config.rb
    lib/diecut/ui-applier.rb
    lib/diecut/mediator.rb
    lib/diecut/configurable.rb
    lib/diecut/mustache.rb
    lib/diecut/template-reducer.rb
    lib/diecut/linter.rb
    lib/diecut/plugin-description.rb
    lib/diecut/plugin-loader.rb
    lib/diecut/errors.rb
    lib/diecut/template-set.rb
    lib/diecut.rb

    lib/diecut/error-report.rb
    lib/diecut/report-builder.rb
    lib/diecut/report-builders/exception-report.rb
    lib/diecut/report-builders/invalid-plugin.rb
    lib/diecut/report-builders/missing-context-field.rb
    lib/diecut/report-builders/option-collision.rb
    lib/diecut/report-builders/orphaned-field.rb
    lib/diecut/report-builders/overridden-context-defaults.rb
    lib/diecut/report-builders/template-list.rb
    lib/diecut/report-builders/unused-default.rb

    bin/diecut
    spec/register_plugin_spec.rb
    spec/template_spec.rb
    spec/spec_helper.rb
    spec/plugin_loader_spec.rb
    spec/template-reducer_spec.rb
    spec/mill_spec.rb
    spec/linter_spec.rb
    spec/template_set_spec.rb
    spec/configurable_spec.rb
    spec/stemming_kinds_spec.rb
    spec/cli_spec.rb
  ]

  spec.bindir = 'bin'
  spec.executables = %w(diecut)

  spec.test_file        = "gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} Documentation"]

  spec.add_dependency("mustache", "~> 1.0")
  spec.add_dependency("calibrate", "~> 0.0.1")
  spec.add_dependency("valise", "~> 1.2")
  spec.add_dependency("thor", "~> 0.19")
  spec.add_dependency("paint", "~> 0.8")
  #spec.add_dependency("", "> 0")

  #spec.post_install_message = "Thanks for installing my gem!"
end
