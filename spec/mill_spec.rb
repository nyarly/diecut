require 'diecut/mill'

describe Diecut::Mill do
  subject :mill do
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

  let :other_plugin do
    Diecut::PluginDescription.new('icky', 'icky.rb')
  end

  before :each do
    mill.mediator.add_plugin(plugin)
    mill.mediator.add_plugin(other_plugin)
  end

  it "should render files" do
    mill.activate_plugins do |name|
      name == 'dummy'
    end
    ui = mill.user_interface

    ui.testing = "checking"
    ui.thing = "test file"

    mill.churn(ui) do |path, contents|
      expect(path).to eq "checking.txt"
      expect(contents).to eq "I am a test file for checking"
    end
  end
end
