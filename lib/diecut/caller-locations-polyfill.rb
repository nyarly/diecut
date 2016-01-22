module Diecut
  module CallerLocationsPolyfill
    unless Kernel.instance_method(:caller_locations)
      # :nocov:
      FakeLocation = Struct.new(:absolute_path, :lineno, :label)
      LINE_RE = %r[(?<absolute_path>[^:]):(?<lineno>\d+):(?:in `(?<label>[^'])')?]
      # covers exactly the use cases we need
      def caller_locations(range, length=nil)
        caller[range.begin+1..range.end+1].map do |line|
          if m = LINE_RE.match(line)
            FakeLocation.new(m.named_captures.values_at("absolute_path", "lineno", "label"))
          end
        end
      end
      # :nocov:
    end
  end
end
