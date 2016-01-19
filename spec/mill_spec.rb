require 'diecut/mill'

describe Diecut::Mill do
  subject :mill do
    Diecut::Mill.new.tap do |mill|
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

  it "should render files" do
    mill.prepare
    mill.templates.context.testing = "checking"
    mill.templates.context.thing = "test file"

    mill.results do |path, contents|
      expect(path).to eq "checking.txt"
      expect(contents).to eq "I am a test file for checking"
    end
  end
end
