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

    context "valid formats" do
      context "json" do
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
      context "xml" do
      end
    end
  end

  describe "#requires" do
    let(:klass) {
      class Test
        include Sirius
        requires :foo, String
      end
    }
    context "json attribute" do
      context "with data" do
        subject { klass.new(:json, '{"foo":"bar"}') }
        it{ should respond_to(:foo) }
        its(:foo) { should == "bar" }
        it{ should be_valid }
      end
      context "without data" do
        subject { klass.new(:json, '{"foo": null}') }
        it{ should_not be_valid }
      end
    end
    context "xml attribute" do
      context "with data" do
        subject { klass.new(:xml, '<foo>bar</foo>') }
        it{ should respond_to(:foo) }
        its(:foo) { should == "bar" }
        it{ should be_valid }
      end
      context "without data" do
        subject { klass.new(:xml, '<foo></foo>') }
        it{ should_not be_valid }
      end
    end
  end
end
