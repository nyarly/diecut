require 'diecut/configurable'

describe Diecut::Configurable do
  let :subclass do
    Class.new(described_class){
      setting :shallow
      setting :deeply, Class.new(Diecut::Configurable){
        setting :nested, Class.new(Diecut::Configurable){
          setting :field
        }
      }
    }.tap do |subclass|
      subclass.target_name = "for something"
    end
  end

  it "inspects nicely" do
    expect(subclass.inspect).to match(/Configurable.*something.*deeply\.nested\.field/)
  end
end
