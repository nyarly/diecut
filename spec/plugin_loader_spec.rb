require 'diecut/plugin-loader'

describe Diecut::PluginLoader do
  let :root_gem do
    instance_double('Gem::Specification', "root", :name => 'root', :matches_for_glob => ['/root_path/diecut_plugin.rb'],
                   :dependencies => [])
  end

  let :simple_dep do
    instance_double('Gem::Specification', 'simple', :name => 'simple', :matches_for_glob => ['/simple_path/diecut_plugin.rb'],
                    :dependencies => [instance_double("Gem::Dependency", :name => "root")] )
  end

  let :side_dep do
    instance_double('Gem::Specification', 'side', :name => 'side', :matches_for_glob => ['/side_path/diecut_plugin.rb'],
                    :dependencies => [
                      instance_double("Gem::Dependency", :name => "root"),
                      instance_double("Gem::Dependency", :name => "simple"),
                      instance_double("Gem::Dependency", :name => "cycle")
                    ])
  end

  let :cycle_dep do
    instance_double('Gem::Specification', 'cycle', :name => 'cycle', :matches_for_glob => ['/cycle_path/diecut_plugin.rb'],
                    :dependencies =>[ instance_double("Gem::Dependency", :name => "side") ])
  end

  let :gem_specs do
    [root_gem, simple_dep, side_dep, cycle_dep]
  end

  let :plugin_defs do
    {
      "/root_path/diecut_plugin.rb" => proc{
        loader.describe_plugin("root"){}
      },
      "/simple_path/diecut_plugin.rb" => proc{
        loader.describe_plugin("simple"){}
      },
      "/side_path/diecut_plugin.rb" => proc{
        loader.describe_plugin("side"){}
      },
      "/cycle_path/diecut_plugin.rb" => proc{
        loader.describe_plugin("cycle"){}
      },
      "<DEFAULTS>:diecut_plugin.rb" => proc{
        loader.describe_plugin("local"){}
      }
    }
  end

  let :valise do
    Valise::Set.define do
      defaults do
        file "diecut_plugin.rb", "I am a thing for testing"
      end
    end
  end

  subject :loader do
    Diecut::PluginLoader.new.tap do |loader|
      loader.local_valise = valise
      current_caller = "no clue"
      allow(loader).to receive(:caller_locations){ [current_caller] }
      allow(loader).to receive(:latest_specs).and_return(gem_specs)
      allow(loader).to receive(:require_plugin) {|path|
        current_caller = double("Location", :absolute_path => path)
        plugin_defs.fetch(path).call
      }
    end
  end

  let :root_plugin do
    loader.plugins.find{|pl| pl.name == 'root' }
  end

  let :simple_plugin do
    loader.plugins.find{|pl| pl.name == 'simple' }
  end

  let :side_plugin do
    loader.plugins.find{|pl| pl.name == 'side' }
  end

  let :cycle_plugin do
    loader.plugins.find{|pl| pl.name == 'cycle' }
  end

  let :local_plugin do
    loader.plugins.find{|pl| pl.name == 'local' }
  end

  before :each do
    loader.load_plugins
  end


  it "should load some plugins" do
    expect(loader.plugins.length).to eq(5)
  end

  it "should trace sequencing" do
    expect(loader.strict_sequence?(root_plugin, local_plugin)).to eq(true)
    expect(loader.strict_sequence?(local_plugin, root_plugin)).to eq(false)
    expect(loader.strict_sequence?(root_plugin, simple_plugin)).to eq(true)
    expect(loader.strict_sequence?(root_plugin, cycle_plugin)).to eq(true)
    expect(loader.strict_sequence?(side_plugin, cycle_plugin)).to eq(true)
  end
end
