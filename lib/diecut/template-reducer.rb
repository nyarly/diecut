module Diecut
  class TemplateReducer
    def initialize(tokens)
      @tokens = tokens
    end

    def fields
      process([], [@tokens]) if @fields.nil?
      @fields.keys
    end

    def sections
      process([], [@tokens]) if @sections.nil?
      @sections.keys
    end

    def partials
      process([], [@tokens]) if @partials.nil?
      @partials.keys
    end

    def unknown
      process([], [@tokens]) if @unknown.nil?
      @unknown
    end

    def leaf_fields
      leaves_and_nodes if @leaf_fields.nil?
      return @leaf_fields
    end

    def node_fields
      leaves_and_nodes if @node_fields.nil?
      return @node_fields
    end

    def leaves_and_nodes
      @node_fields, @leaf_fields = fields.partition.with_index do |field, idx|
        fields.drop(idx + 1).any? do |other|
          field.zip(other).all? {|l,r|
            l==r}
        end
      end
    end

    # XXX Used as a section and as a field is different from used as a field
    # and as parent of a field. Tricky tricky
    def validate
      not_sections = node_fields.find_all {|node| !sections.include?(node)}
      unless not_sections.empty?
        warn "These fields are referenced directly, and as the parent of another field:\n" +
          not_sections.map{|sec| sec.join(".")}.join("\n")
      end
    end

    def process(prefix, tokens)
      @fields ||= {}
      @partials ||= {}
      @unknown ||= []
      @sections ||= {}

      tokens.each do |token|
        case token[0]
        when :multi
          process(prefix, token[1..-1])
        when :static
        when :mustache
          case token[1]
          when :etag, :utag
            process(prefix, [token[2]])
          when :section, :inverted_section
            @sections[prefix + token[2][2]] = true
            process(prefix, [token[2]])
            process(prefix + token[2][2], [token[4]])
          when :partial
            @partials[[token[2], prefix]] = true
          when :fetch
            @fields[prefix + token[2]] = true
          else
            @unknown << token
          end
        else
          @unknown << token
        end
      end
    end
  end
end
