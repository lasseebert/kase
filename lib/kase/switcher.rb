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
      context = eval("self", block.binding)
      dsl = DSL.new(self, context)
      dsl.__call(&block)
      validate!
      result
    end

    class DSL
      def initialize(switcher, context)
        @__switcher = switcher
        @__context = context
      end

      def __call(&block)
        @__context.instance_variables.each do |name|
          next if name.to_s =~ /^@__/
          instance_variable_set(name, @__context.instance_variable_get(name))
        end

        instance_eval(&block)

        instance_variables.each do |name|
          next if name.to_s =~ /^@__/
          @__context.instance_variable_set(name, instance_variable_get(name))
        end
      end

      def on(*args, &block)
        @__switcher.on(*args, &block)
      end

      def method_missing(method, *args, &block)
        @__context.send(method, *args, &block)
      end
    end
  end
end
