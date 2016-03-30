require "kase/switcher"
require "kase/version"

module Kase
  module_function

  def kase(*values, &block)
    Switcher.new(*values).switch(&block)
  end

  def ok!(*values, &block)
    Switcher.new(*values).switch do
      on(:ok) do |*result|
        if block_given?
          yield(*result) if block_given?
        else
          case result.size
          when 0
            nil
          when 1
            result.first
          else
            result
          end
        end
      end
    end
  end
end
