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

    # Diecut's templates aren't HTML files - if they need escaping it should
    # happen in the source file
    def escapeHTML(str)
      str
    end
  end
end
