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

        # Preserve original on method
        original_on = context.method(:on) if defined? context.on

        # Define new on method
        context.define_singleton_method(:on) do |*pattern, &block|
          switcher.on(*pattern, &block)
        end

        block.call

        # Replace original :on
        context.instance_eval { undef :on }
        context.define_singleton_method(:on, original_on) if original_on
      end
    end
  end
end
