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

  before :each do
    mill.mediator.add_plugin(plugin)
    mill.mediator.add_plugin(option_colision_plugin)
  end

  subject :linter do
    Diecut::Linter.new(mill)
  end

  let :report do
    linter.report
  end

  describe "happy set of plugins" do
    it "should produce a report" do
      puts "\n#{__FILE__}:#{__LINE__} => \n#{linter.report}"
      expect(report).to match(/Total QA failing reports: 0/)
    end
  end

  describe "with an option collision" do
    before :each do
      mill.mediator.activate('icky')
    end

    it "should produce a report" do
      puts "\n#{__FILE__}:#{__LINE__} => \n#{linter.report}"
      expect(report).to match(/Option collisions: FAIL/)
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
      puts "\n#{__FILE__}:#{__LINE__} => \n#{linter.report}"
      expect(report).to match(/Template fields all have settings: WARN/)
      expect(report).to match(/Output field\s+Source file/)
      expect(report).to match(/thing\s+{{testing}}.txt/)
      expect(report).not_to match(/^\s*testing\b/)
      expect(report).to match(/Total QA failing reports:/)
    end
  end
end
