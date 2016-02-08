require 'diecut'

describe "Diecut.plugin" do
  let :loader do
    Diecut::PluginLoader.new.tap do |loader|
      allow(loader).to receive(:choose_source).and_return("dont/care/where")
    end
  end

  before :each do
    Diecut.clear_plugins

    Diecut.plugin_loader = loader
    Diecut.plugin("test") do |plugin|
      plugin.for_kind("app")
      plugin.default_off

      plugin.default(%w(budgies count), 10)
      plugin.default(%w(budgies birthday)) do |context|
        Time.now
      end

      plugin.option(:alive) do |alive|
        alive.description "Are the budgies alive?"
        alive.goes_to("budgies", "living")
      end

      plugin.option(:name_seed) do |name|
        name.description "Used to name all the budgies"
        name.default "Bruce"
      end

      plugin.resolve do |ui, context|
        context.budgies.names = context.budgies.count.times.map do |idx|
          "#{ui.name_seed} ##{idx}"
        end
      end
    end
  end

  after :each do
    Diecut.clear_plugins
  end

  let :context_class do
    budgie_class = Class.new(Diecut::Configurable) do
      setting :count
      setting :birthday
      setting :living
      setting :names
    end

    Class.new(Diecut::Configurable) do
      setting :budgies, budgie_class
    end
  end

  let :mediator do
    Diecut.mediator("app")
  end

  it "should activate and deactivate plugins" do
    expect(mediator.activated?("test")).to eq false
    mediator.activate("test")
    expect(mediator.activated?("test")).to eq true
    mediator.deactivate("test")
    expect(mediator.activated?("test")).to eq false
  end

  it "should process the whole thing" do
    mediator.activate("test")
    ui_class = mediator.build_ui_class(context_class)

    expect(ui_class.field_names).to contain_exactly(:name_seed, :alive)
    expect(ui_class.required?(:name_seed)).to eq false
    expect(ui_class.default_for(:name_seed)).to eq "Bruce"
    expect(ui_class.required?(:alive)).to eq true
    expect(ui_class.description(:alive)).to match(/alive\?/)

    ui = ui_class.new

    ui.alive = true
    ui.name_seed = "Jane"

    context = mediator.apply_user_input(ui, context_class)

    expect(context.budgies.count).to eq 10
    expect(context.budgies.birthday).to be_a(Time)
    expect(context.budgies.living).to eq true
    expect(context.budgies.names.length).to eq 10
    expect(context.budgies.names).to include("Jane #3")
  end

  it "should produce an example UI" do
    ui_class = mediator.build_example_ui
    expect(ui_class.field_names).to contain_exactly(:name_seed, :alive)
    expect(ui_class.required?(:name_seed)).to eq false
    expect(ui_class.required?(:alive)).to eq true
    expect(ui_class.description(:alive)).to match(/alive\?/)
  end

  it "should leave out options for deactivated plugins" do
    expect(mediator.activated?("test")).to eq false
    ui_class = mediator.build_ui_class(context_class)
    expect(ui_class.field_names).to be_empty
  end
end
