require "kase/errors"

module Kase
  class Switcher
    def initialize(*values)
      if values.size == 1 && values.first.is_a?(Array)
        values = values.first
      end
      @values = values
      @matched = false
    end

    attr_reader :values
    attr_reader :result

    def matched?
      !!@matched
    end

    def match?(*pattern)
      values[0...pattern.size] == pattern
    end

    def on(*pattern)
      return if matched?
      return unless match?(*pattern)
      @matched = true
      @result = yield(*values[pattern.size..-1])
    end

    def validate!
      raise NoMatchError.new(values) unless matched?
      true
    end

    def switch(&block)
      DSL.call(self, &block)
      validate!
      result
    end

    module DSL
      module_function

      def call(switcher, &block)
        context = eval("self", block.binding)
        original_on_method = context.method(:on) if defined? context.on
        new_on_method = nil

        # Define a new :on method for the caller context
        context.define_singleton_method(:on) do |*pattern, &inner_block|

          new_inner_block = proc do |*args|
            # Use the original :on method inside the inner blocks
            DSL.set_on_method(context, original_on_method)
            result = inner_block.call(*args)
            DSL.set_on_method(context, new_on_method)
            result
          end

          switcher.on(*pattern, &new_inner_block)
        end
        new_on_method = context.method(:on)

        block.call
      ensure
        DSL.set_on_method(context, original_on_method)
      end

      def set_on_method(context, method)
        if method
          context.define_singleton_method(:on, method)
        else
          context.instance_eval { undef :on }
        end
      end
    end
  end
end
