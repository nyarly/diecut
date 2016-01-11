require 'diecut/template'
require 'diecut/mustache'

describe Diecut::Template do
  let :tmpl do
    tmpl = Diecut::Template.new("somewhere", <<EOT)
I am a {{thing}} with {{ very.deep.values }}.
{{#sometimes}}I tell secrets {{#lengthy}}at length {{/lengthy}}- also {{sometime}}
{{/sometimes}}
{{^sometimes}}I am an open book{{/sometimes}}{{! this is silly }}
Oh: something else: {{< apartial}}
This too: {{#nested}}{{< apartial}}{{/nested}}
EOT
    tmpl
  end

  let :prtl do
    Diecut::Template.new("apartial", <<EOT)
I'm {{status}}
EOT
  end

  let :renderer do
    renderer = Diecut::Mustache.new
    renderer.partials_hash = {
      :somewhere => tmpl,
      :apartial => prtl
    }
    renderer
  end

  before :each do
    tmpl.partial_context(prtl)

    tmpl.context.from_hash(
      thing: "template",
      very: { deep: { values: "strongly held beliefs" }},
      sometimes: [
        { sometime: "stories", lengthy: false },
        { sometime: "lies", lengthy: true }
      ],
      status: "green",
      nested: { status: "yellow" }
    )
  end

  it "renders a string based on config" do

    expect(tmpl.render(renderer)).to eq(<<EOS)
I am a template with strongly held beliefs.
I tell secrets - also stories
I tell secrets at length - also lies

Oh: something else: I'm green

This too: I'm yellow

EOS
  end
end
