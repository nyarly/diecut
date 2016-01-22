module Diecut
  class PluginDescription
    class ContextDefault < Struct.new(:context_path, :value, :block)
      def simple?
        value != NO_VALUE
      end

      def compute_value(context)
        block.call(context)
      end
    end
  end
end
