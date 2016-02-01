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
      }
    }
  end

  let :valise do
    Valise::Set.define do
      defaults do
        file "{{testing}}.txt", "I am a {{thing}} for {{testing}}"
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


  it "should load some plugins" do
    loader.load_plugins
    expect(loader.plugins.length).to eq(4)
  end
end
