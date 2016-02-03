require 'diecut/error-report'

describe Diecut::ErrorHandling::Reporter do
  let :mill do
    instance_double('Diecut::Mill')
  end

  subject :reporter do
    described_class.new(mill)
  end

  it "should produce some reports" do
    reporter.missing_context_field("plugin_name", "option_name", %w(context_path))
    reporter.unused_default("plugin_name", %w(context_path))
    reporter.invalid_plugin("name", %w(context_path), "value")
    expect{reporter.handle_exception(Diecut::Error.new("test exception"))}.not_to raise_error

    expect(reporter.reports.length).to be(4)
  end
end
