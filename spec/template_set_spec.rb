require 'diecut/template-set'

describe Diecut::TemplateSet do
  subject :template_set do
    Diecut::TemplateSet.new
  end

  it "should render files" do
    template_set.add "{{testing}}.txt", "I am a {{thing}} for {{testing}}"
    template_set.prepare
    template_set.context = template_set.context_class.new

    template_set.context.setup_defaults
    template_set.context.testing = "checking"
    template_set.context.thing = "test file"

    template_set.results do |path, contents|
      expect(path).to eq "checking.txt"
      expect(contents).to eq "I am a test file for checking"
    end
  end
end
