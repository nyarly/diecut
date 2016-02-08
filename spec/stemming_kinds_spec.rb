require 'diecut/mill'
require 'file-sandbox'

describe Diecut::Mill do
  include FileSandbox
  before :each do
    Diecut.clear_plugins

    sandbox["resource/src/common/resources/{{resource_name}}.js"].contents = "yup"
    sandbox["mappers/app/mappers/{{mapper_name}}.rb"].contents = "yup"
  end

  before :each do
    Diecut.plugin("relayer-resource") do |resource|
      resource.for_kind("xing", File.join(sandbox.root, "resource")) do |xing|
        xing.stem = 'frontend'
      end

      resource.for_kind('angular-one', File.join(sandbox.root, "resource")) do |ng|
        ng.default_off
      end
    end
  end

  before :each do
    Diecut.plugin("rails-mapper") do |mapper|
      mapper.for_kind("xing", File.join(sandbox.root, "mappers")) do |xing|
        xing.stem = 'backend'
      end

      mapper.for_kind('rails', File.join(sandbox.root, "mappers"))
    end
  end

  after :each do
    Diecut.clear_plugins
  end

  let :path_list do
    mill.load_files
    mill.templates.templates.map{|n, template| template.path}
  end

  describe "Mixed with stems" do
    let :mill do
      Diecut::Mill.new("xing")
    end

    it "should have files in stemmed directories" do
      expect(path_list).to include("frontend/src/common/resources/{{resource_name}}.js", "backend/app/mappers/{{mapper_name}}.rb")
    end
  end

  describe "Simpler kind" do
    let :mill do
      Diecut::Mill.new("rails")
    end

    it "should have files in stemmed directories" do
      expect(path_list).to include("app/mappers/{{mapper_name}}.rb")
    end
  end

  describe "Simpler, but defaults off for kind" do
    let :mill do
      Diecut::Mill.new("angular-one")
    end

    it "should have files in stemmed directories" do
      expect(path_list).to eq([])
    end

    it "should get the files if enables" do
      mill.activate_plugins{ true }
      expect(path_list).to include("src/common/resources/{{resource_name}}.js")
    end
  end
end
