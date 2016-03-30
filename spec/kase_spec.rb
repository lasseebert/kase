require "kase"

RSpec.describe Kase do
  include Kase

  it "has a version number" do
    expect(Kase::VERSION).not_to be nil
  end

  describe "#kase" do
    it "delegates to switcher" do
      value = kase :ok, "RESULT" do
        on(:ok) { |result| result }
      end

      expect(value).to eq("RESULT")
    end
  end

  describe "#ok!" do
    it "returns nil on one value" do
      result = ok! :ok
      expect(result).to be_nil
    end

    it "returns a single result on two values" do
      result = ok! :ok, "RESULT"
      expect(result).to eq("RESULT")
    end

    it "returns an array on more values" do
      result = ok! :ok, "RESULT", "ONE MORE"
      expect(result).to eq(["RESULT", "ONE MORE"])
    end

    it "yields" do
      result = ok! :ok, "RESULT" do |res|
        res + " yielded"
      end
      expect(result).to eq("RESULT yielded")
    end

    it "raises on no match" do
      expect { ok! :error }.to raise_error(Kase::NoMatchError)
    end
  end
end
