require "kase/switcher"

module Kase
  RSpec.describe Switcher do
    describe "initialization" do
      it "accepts an array" do
        switcher = Switcher.new([:a, :b])
        expect(switcher.values).to eq([:a, :b])
      end

      it "accepts separate values" do
        switcher = Switcher.new(:a, :b)
        expect(switcher.values).to eq([:a, :b])
      end

      it "accepts a single argument" do
        switcher = Switcher.new(:a)
        expect(switcher.values).to eq([:a])
      end
    end

    describe "#match?" do
      true_examples = [
        [[:a], [:a]],
        [[:a], [:a, :b]],
        [[:a, :b], [:a, :b]],
        [[:a, :b], [:a, :b, :c]],
        [[], [:a, :b]],
      ]

      false_examples = [
        [[:a], [:b]],
        [[:a], [:b, :a]],
        [[:a, :b], [:a, :c, :b]],
      ]

      true_examples.each do |pattern, values|
        it "matches #{pattern} on #{values}" do
          switcher = Switcher.new(values)
          expect(switcher.match?(*pattern)).to be true
        end
      end

      false_examples.each do |pattern, values|
        it "does not match #{pattern} on #{values}" do
          switcher = Switcher.new(values)
          expect(switcher.match?(*pattern)).to be false
        end
      end
    end

    describe "#on" do
      def switcher
        @switcher ||= Switcher.new(:a, :b)
      end

      it "calls the block if pattern matches" do
        called_with = nil
        switcher.on(:a) { |result| called_with = result }

        expect(called_with).to eq(:b)
      end

      it "returns the value of the block" do
        result = switcher.on(:a) { |_result| :yes }
        expect(result).to eq(:yes)
      end

      it "sets the result if pattern matches" do
        switcher.on(:a) { |_result| :yes }
        expect(switcher.result).to eq(:yes)
      end

      it "does not call the block if pattern does not match" do
        called = false
        result = switcher.on(:b) { called = true }

        expect(called).to be false
        expect(result).to be_nil
      end

      it "does not call the block if another result was already found" do
        switcher.on(:a) { :first }
        switcher.on(:a, :b) { :second }

        expect(switcher.result).to eq(:first)
      end
    end

    describe "#validate!" do
      it "raises NoMatchError if not matched" do
        expect {
          Switcher.new.validate!
        }.to raise_error(NoMatchError)
      end

      it "returns true if matched" do
        switcher = Switcher.new(:a)
        switcher.on(:a) { :yes }

        expect(switcher.validate!).to be true
      end
    end

    describe "#switch" do
      it "combines the whole lot in a simple dsl" do
        result = Switcher.new(:ok, "RESULT").switch do
          on(:ok) { |res| res }
          on(:error) { |message| raise message }
        end

        expect(result).to eq("RESULT")
      end

      it "raises on no match" do
        expect {
          Switcher.new(:fail).switch do
            on(:ok) { |result| result }
            on(:error) { |message| raise message }
          end
        }.to raise_error(NoMatchError)
      end

      it "can use local methods inside dsl" do
        example_class = Class.new do
          def pattern
            :ok
          end

          def call
            Switcher.new(:ok, "RESULT").switch do
              on(pattern) { |result| result }
            end
          end
        end

        result = example_class.new.call

        expect(result).to eq("RESULT")
      end
    end
  end
end
