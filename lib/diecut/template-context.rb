module Diecut
  module TemplateContext
    def self.add(path, klass)
      name = path.gsub(%r{\.}, " dot ").gsub(%r{(?:\A|[\s/{}]+)(\w)}){ $1.upcase }
      const_set(name, klass)
    end
  end
end
