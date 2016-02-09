# Diecut

Diecut is a code generation library. It's designed to allow complicated code
generation tasks to be accomplished in a straighforward, directed way.

## Use Case

The motivating use case for Diecut looks like this.

Suppose you have some example code you'd like to convert into a set of
templates that you can stamp out - for instance, in order to start new
projects, or to skip past the initial boilerplate required by a framework.

Start by creating a new Ruby gem. You can use whatever method you like to do
this (a generator specific to Diecut projects is in the works) - you can
`bundle gem` for instance, or use Corundum. Add Diecut as a dependency:

```ruby
spec.add_dependency "diecut", ">= 0.0.3", "< 1.0"
```

Probably you want to run `bundle` now in order to bring everything in.


Create a `lib/diecut_templates` directory, as well as `lib/diecut_plugin.rb`.
Copy your code into lib/diecut_templates.

```
lib/
  diecut_plugin.rb
  diecut_templates/
    <your code>.rb
```

In lib/diecut_plugin.rb, add code like this:

```
Diecut.plugin('relayer-resource') do |corundum|
  corundum.for_kind('xing-scaffold')
end
```

Assuming that you've got your gem and bundler set up correctly, you should now
be able to run `diecut help` and see your new 'kind' is available:

```
⮀ diecut help
Commands:
  diecut xing-scaffold                  # Commands related to templating for corundum
  diecut xing-scaffold generate TARGET  # Generate corundum output
  diecut xing-scaffold lint             # Check well-formed-ness of corundum code generators
  diecut help [COMMAND]                 # Describe available commands or one specific command
```

The commands we're most interested in here are `diecut xing-scaffold lint` and
`diecut xing-scaffold generate TARGET`.

If you run `diecut xing-scaffold lint` you'll get output like:

```
Templates included   OK
Template path
<<your code files>>
Overridden context defaults   OK
Option collisions   OK
Template fields all have settings   OK
Unused options   OK
Defaults are declared but unused   OK
General plugin health   OK
Exceptions raised during  definition   OK

Total QA report items: 5
Total QA failing reports: 0
```

Which is nice to see. Basically, we've set up an elaborate copy operation, and
we wouldn't expect there to be anything wrong with it. You can even try it out
with `diecut xing-scaffold generate /tmp/test-generate` - you'll get a nice
list of all the files it copied into place. Notice that the copy happens from
your `lib/diecut_templates` directory into `/tmp/test-generate.`

Generally, we want to be able to generate files based on a template, however.
Diecut is designed to make this as smooth a process as possible.

First, mark up your source files with
[Mustache](http://mustache.github.io/mustache.5.html) syntax. Mostly, you can
simply do search and replace for words to change e.g.

```
class Tubas < Instrument
  def name
    "tuba"
  end
end
```

into

```
class {{classname}} < Instrument
  def name
    "{{stringname}}"
  end
end
```

You can even use Mustache markup in path names - so the above code might wind
up residing in 'app/instruments/{{stringname}}_class.rb' - note that most
shells will need you to treat file names with '{{}}' in them specially - you'll
need to use single quotes, for instance.

Note that, now, if you run `diecut xing-scaffold lint`, you'll get errors and
warnings about how 'Template fields all have settings: FAIL' because
`classname` and `stringname` don't have values.

Where do your templates get their field values from? Your `diecut_plugin.rb`
file provides all of that. Here's a rundown:

```
Diecut.plugin("budgies") do |plugin|
  plugin.for_kind("petshop")
  plugin.default_off # Most of the time you don't want this, but for plugins
                     # that provide optional functionality, you might.

  plugin.default('budgies.count', 10) # A simple default value

  # This defines a default for a template field with a block to compute its
  # value. Time.now is a example of what you'd do with this.
  plugin.default(%w(budgies birthday)) do |context|
    Time.now
  end

  # This defines a user interface option (e.g. --alive=true)
  plugin.option(:alive) do |alive|
    # The description is available to be used in e.g. --help
    alive.description "Are the budgies alive?"
    # .goes_to sets the template field that the option will get set to
    alive.goes_to("budgies.living")
  end

  plugin.option(:name_seed) do |name|
    # Sets a default value for the option - options are required iff they don't have a default value
    name.default "Bruce"
  end

  # Resolve is the loophole for computing values just before templating.
  # The first argument is the UI object, populated from the command line -
  #   any named option is available as a reader method.
  # The second is the templating context, which likewise has readers and writers for all its fields.
  plugin.resolve do |ui, context|
    context.budgies.names = context.budgies.count.times.map do |idx|
      "#{ui.name_seed} ##{idx}"
    end
  end
end
```

In broad strokes, you'll set up options and defaults to provide values for the
fields you defined by adding them to your template files. `diecut lint` will
help guide you to which fields still need to be updated and catch the common
issues that come up.

## Your Own Command

Once you're satisfied with your Diecut generator, you can advise your users to
simply use `diecut <kind> generate,` but it's really easy to add your own
command. In `bin/your-generator` in your gem project, add:

```
require 'diecut/cli'
Diecut.load_plugins
module YourProject
  CLI = Diecut::Cli::TargetedGenerate.subclass_for('your-kind')
end

YourProject::CLI.start
```

You can try it out with `bundle exec bin/your-generator` - things like `--help`
should work:
```
⮀ bundle exec bin/your-generator --help
Usage:
  your-generator TARGET The directory to use as the root of generated output --an-option=ANOPTION

Options:
  [--with-your-base=WITH-YOUR-BASE]   # Default: true
  --an-option=ANOPTION                # Option's description here
```

and you should be able to use it to generate code the same way you
can with `diecut your-kind generate` which is pretty neat. Once you release the
gem, your users should be able to just `your-generator` - the `bundle exec`
thing has to do with working with local gems.

## Advanced Topics

Diecut tries to make a surprisingly complex problem more tractible. As a
result, there are a few wrinkles to know about as you work forward with it.

### Kinds and Plugins

When generating code, you usually have several different kinds of code you want
to generate. Consider how Rails has `scaffold` and `migration` and `model` and
`controller` and ... Even given all those "kinds" of code to generate, there
are different files and considerations about how to do the generation. That's
where plugins come in. Each plugin can provide some (or all!) of a kind of code
to generate, and if multiple plugins all contribute to the same kind, they'll
be blended in a predicable, reasonable way.

Plugins are loaded in order of _gem dependency_, with later plugins (i.e. those
whose gems declare depencies on earlier ones) overriding earlier ones. Their
template files replace the earlier ones, their plugin configurations (options
and defaults etc) override the eariler ones. The linter helps a lot with
accidental overrides, which should cover most of the bases there.

Just being available as a gem makes the plugins available, so simply adding a
useful override to your Gemfile is enough to bring it into a particular kind of
generation.

Plugins might also be useful to more than one kind of generation. Considering
Rails again, the `scaffold` kind is almost exactly the composition of several
other kinds. Diecut's approach here is that the different plugins would each
register as `plugin.for_kind('model')` and `plugin.for_kind('scaffold')`, which
would bring them all into the right kinds of generation.


### More Plugin Tricks
There's no need, necessarily, for plugins to be one-for-one with gems, either.

Let's look again at the `for_kind` method:

```
Diecut.plugin('complicated') do |complex|
  mapper.for_kind("xing") do |xing|
    xing.template_dir = 'diecut_templates/complex'
    xing.stem = 'backend'
    xing.default_off
  end
end
```

Setting `template_dir` lets us use any directory in our gem as the source for
our templates, which especially means we could have more than one directory
used for templates in the same gem.

Setting `stem` lets us use a prefix on the files in the plugin. If, for
instance, you were writing a Diecut plugin for [refactoring Rails
models](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/)
and thought they might be useful for writing [Xing
backends](http://xingframework.com), you could add a second
`seven_ways.for_kind("xing"){|xing| xing.stem = 'backend'}` to your plugin and
be sure the files would get into the right place.

Setting `default_off` lets us say that this plugin isn't on by default for a
particular kind, even though it's on for most kinds.
