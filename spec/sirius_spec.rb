require 'sirius'
require 'json'

describe Sirius do
  describe ".initialize" do
    let(:klass) { class Test; include Sirius; end }

    context "with unknown format" do
      it "raises UnknownSerializationFormat error" do
        expect{ klass.new(:wrong, '') }.to raise_error
      end
    end

    context "with valid format" do
      context "and valid data" do
        it "initializes successfully" do
          expect{ klass.new(:json, '{"foo":"bar"}') }.not_to raise_error
        end
      end
      context "and invalid data" do
        it "blows up" do
          expect{ klass.new(:json, '') }.to raise_error
        end
      end
    end

    describe "required single variables" do
      let(:klass) {
        class Test
          include Sirius
          requires :foo, String
        end
      }
      subject { klass }
      it{ should respond_to(:foo) }
    end
  end
end
