require 'diecut/mill'
require 'diecut/linter'

describe Diecut::Mill do
  let :mill do
    Diecut::Mill.new("kind").tap do |mill|
      mill.valise = valise
    end
  end

  let :valise do
    Valise::Set.define do
      defaults do
        file "{{testing}}.txt", "I am a {{thing}} for {{testing}}"
      end
    end
  end

  let :plugin do
    Diecut::PluginDescription.new('dummy', 'dummy.rb').tap do |plugin|
      plugin.option('testing') do |opt|
        opt.goes_to('testing')
      end
      plugin.option('thing') do |opt|
        opt.goes_to(['thing'])
      end
      plugin.default('thing', 15)
    end
  end

  let :option_colision_plugin do
    Diecut::PluginDescription.new('icky', 'icky.rb').tap do |plugin|
      plugin.default_off
      plugin.option('context_colision') do |opt|
        opt.goes_to('testing')
      end
    end
  end

  let :default_override_plugin do
    Diecut::PluginDescription.new('stinky', 'stinky.rb').tap do |plugin|
      plugin.default_off
      plugin.default('thing', 'fifteen')
    end
  end

  let :plugins do
    [plugin, option_colision_plugin, default_override_plugin]
  end

  let :loader do
    instance_double("Diecut::PluginLoader").tap do |loader|
      allow(loader).to receive(:strict_sequence?).and_return(false)
      allow(loader).to receive(:plugins).and_return(plugins)
    end
  end

  before :each do
    allow(Diecut).to receive(:plugin_loader).and_return(loader)

    plugins.each do |plugin|
      mill.mediator.add_plugin(plugin, plugin.default_active?)
    end
  end

  subject :linter do
    Diecut::Linter.new(mill)
  end

  let :report do
    linter.report
  end

  describe "happy set of plugins" do
    it "should produce a report" do
      expect(report).to match(/Total QA failing reports: 0/)
    end
  end

  describe "with an option collision" do
    before :each do
      mill.mediator.activate('icky')
    end

    it "should produce a report" do
      expect(report).to match(/Option collisions\s*FAIL/)
      expect(report).to match(/Total QA failing reports:/)
      expect(report).to match(/there's/)
    end
  end

  describe "with a missing context field" do
    before :each do
      mill.mediator.activate('icky')
      mill.mediator.deactivate('dummy')
    end

    it "should produce a report" do
      expect(report).to match(/Template fields all have settings\s*WARN/)
      expect(report).to match(/Output field\s+Source file/)
      expect(report).to match(/thing\s+{{testing}}.txt/)
      expect(report).not_to match(/^\s*testing\b/)
      expect(report).to match(/Total QA failing reports:/)
    end
  end

  describe "with intentional override of default" do
    before :each do
      mill.mediator.activate("dummy")
      mill.mediator.activate("stinky")
      allow(loader).to receive(:strict_sequence?).with(plugin, default_override_plugin).and_return(true)
    end

    it "should produce a report" do
      expect(report).to match(/Overridden context defaults\s*OK/)
    end
  end

  describe "with accidental override of default" do
    before :each do
      mill.mediator.activate("dummy")
      mill.mediator.activate("stinky")
    end

    it "should produce a report" do
      expect(report).to match(/Overridden context defaults\s*FAIL/)
      expect(report).to match(/Output field\s+Default value\s+Source plugin/)
      expect(report).to match(/thing\s+15\s+dummy/)
      expect(report).to match(/Total QA failing reports:/)
    end
  end
end
