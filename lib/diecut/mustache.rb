require 'mustache'
module Diecut
  class Mustache < ::Mustache
    attr_accessor :partials_hash

    def partial(name)
      partials_hash.fetch(name).template_string
    end

    def raise_on_context_miss?
      true
    end
  end
end
