require 'mustache'
require 'diecut/template-reducer'

describe Diecut::TemplateReducer do
  let :tmpl_string do
    <<EOT
I am a {{thing}} with {{ very.deep.values }}.
{{#sometimes}}I tell secrets {{#lengthy?}}at length{{/lengthy?}} - also {{sometime}}{{/sometimes}}
{{^sometimes}}I am an open book{{/sometimes}}{{! this is silly }}
Oh: something else: {{< apartial}}
This too: {{#nested}}{{< apartial}}{{/nested}}
EOT
  end

  let :reducer do
    Diecut::TemplateReducer.new(Mustache::Parser.new.compile(tmpl_string))
  end

  it "extracts all the fields" do
    expect(reducer.fields).to contain_exactly(%w[thing], %w[very deep values],
                                             %w[nested], %w[sometimes], %w[sometimes lengthy?], %w[sometimes sometime])
  end

  it "filters leaf fields" do
    expect(reducer.leaf_fields).to contain_exactly(%w[thing], %w[very deep values],
                                             %w[nested], %w[sometimes lengthy?], %w[sometimes sometime])
  end

  it "extracts all the sections" do
    expect(reducer.sections).to contain_exactly(%w[sometimes], %w[sometimes lengthy?], %w[nested])
  end

  it "extracts all the partials" do
    expect(reducer.partials).to contain_exactly(["apartial", []], ["apartial", ["nested"]])
  end
end
