require 'first_responder'
require 'json'

describe FirstResponder do
  let(:valid_json) { '{"foo":"bar"}' }
  let(:incomplete_json) { '{"foo": null}' }
  let(:valid_xml) { "<foo>bar</foo>" }
  let(:incomplete_xml) { "<foo></foo>" }
  let(:nested_json) { '{"foo":{"bar":{"baz": "boo"}}}' }
  let(:nested_xml) { '<foo><bar><baz>boo</baz></bar></foo>' }

  describe ".initialize" do
    let(:klass) { Class.new { include FirstResponder } }

    context "with unknown format" do
      it "raises UnknownSerializationFormat error" do
        expect{ klass.new(:wrong, '') }.to raise_error
      end
    end

    context "valid formats" do
      context "json" do
        context "and valid data" do
          it "initializes successfully" do
            expect{ klass.new(:json, valid_json) }.not_to raise_error
          end
        end
        context "and blank data" do
          it "blows up" do
            expect{ klass.new(:json, '') }.to raise_error
          end
        end
      end
      context "xml" do
        context "and valid data" do
          it "initializes successfully" do
            expect{ klass.new(:xml, valid_xml) }.not_to raise_error
          end
        end
        context "and blank data" do
          it "blows up" do
            expect{ klass.new(:xml, '') }.to raise_error
          end
        end
      end
    end
  end

  describe "#requires" do
    let(:klass) {
      Class.new do
        include FirstResponder
        requires :foo, String
        def self.model_name; ActiveModel::Name.new(self, nil, "temp"); end
      end
    }

    context "json attribute" do
      context "with data" do
        subject { klass.new(:json, valid_json) }
        it{ should respond_to(:foo) }
        its(:foo) { should == "bar" }
        it{ should be_valid }
      end
      context "without data" do
        subject { klass.new(:json, incomplete_json) }
        it{ should_not be_valid }
      end
    end

    context "xml attribute" do
      context "with data" do
        subject { klass.new(:xml, valid_xml) }
        it{ should respond_to(:foo) }
        its(:foo) { should == "bar" }
        it{ should be_valid }
      end
      context "without data" do
        subject { klass.new(:xml, incomplete_xml) }
        it{ should_not be_valid }
      end
    end

    describe "extracts passed options" do
      context "with string attrs" do
        let(:klass) {
          Class.new do
            include FirstResponder
            requires :foo, String, at: "['foo']['bar']['baz']"
          end
        }

        context "(json)" do
          subject { klass.new(:json, nested_json) }
          its(:foo) { should == "boo" }
        end
        context "(xml)" do
          subject { klass.new(:xml, nested_xml) }
          its(:foo) { should == "boo" }
        end
      end
      context "with symbol attrs" do
        let(:klass) {
          Class.new do
            include FirstResponder
            requires :foo, String, at: "[:foo][:bar][:baz]"
          end
        }

        context "(json)" do
          subject { klass.new(:json, nested_json) }
          its(:foo) { should == "boo" }
        end
        context "(xml)" do
          subject { klass.new(:xml, nested_xml) }
          its(:foo) { should == "boo" }
        end
      end
    end
  end

  describe ".root" do
    let(:klass) {
      Class.new do
        include FirstResponder
        root "['foo']['bar']"
        requires :foo, String, at: "['baz']"
      end
    }

    context "correctly filters beginning at defined root node" do
      context "(json)" do
        subject { klass.new(:json, nested_json) }
        its(:foo) { should == 'boo' }
      end
      context "(xml)" do
        subject { klass.new(:xml, nested_xml) }
        its(:foo) { should == 'boo' }
      end
    end
  end

  describe "nested first_responder objects" do
    let(:klass) {
      Class.new do
        include FirstResponder
        root "['ocean']['sea_floor']['treasure_chest']['hidden_compartment']"
        requires :treasure, Treasure
      end
    }
    let(:with_treasure) { '{"ocean": { "sea_floor": {"treasure_chest": {"hidden_compartment": { "treasure": { "type": "Gold", "weight": 1, "unit": "Ton" }}}}}}' }

    let(:without_treasure) { '{"ocean": { "sea_floor": {"treasure_chest": {"hidden_compartment": { "treasure": { "type": null, "weight": null, "unit": null}}}}}}' }

    describe "maintains Virtus coercion abilities" do

      before do
        class Treasure
          include Virtus.model
          attribute :type, String
          attribute :weight, Integer
          attribute :unit, String
        end
      end

      subject { klass.new(:json, with_treasure).treasure }
      it{ should be_a(Treasure) }
    end

    describe "validates nested first_responder objects" do
      before do
        class Treasure
          include FirstResponder
          requires :type, String
          requires :weight, Integer
          requires :unit, String

          when_invalid {}
        end
      end

      describe ".nested_validations" do
        it "returns required attributes that must themselves be validated" do
          klass.nested_validations.should == [:treasure]
        end
      end

      describe "#valid?" do
        context "with invalid nested object" do
          subject { klass.new(:json, without_treasure).valid? }
          it{ should be_false }

          context "with proc_on_invalid defined" do
            subject { klass.new(:json, without_treasure) }

            context "by default" do
              it "calls the proc" do
                new_proc = double(:proc)
                subject.stub(:proc_on_invalid).and_return(new_proc)
                new_proc.should_receive(:call)
                subject.valid?
              end
            end
            context "with false passed" do
              it "does not call the proc" do
                new_proc = double(:proc)
                subject.stub(:proc_on_invalid).and_return(new_proc)
                new_proc.should_not_receive(:call)
                subject.valid?(false)
              end
            end
          end

          context "with proc_on_invalid absent" do
            before do
              class Treasure
                include FirstResponder
                requires :type, String
                requires :weight, String
                requires :unit, String
              end
            end

            subject { klass.new(:json, with_treasure) }
            it "does nothing" do
              new_proc = double(:proc)
              subject.stub(:proc_on_invalid).and_return(new_proc)
              new_proc.should_not_receive(:call)
              subject.invalid?
            end
          end
        end

        context "with valid nested object" do
          subject { klass.new(:json, with_treasure).valid? }
          it{ should be_true }
        end
      end

      describe "#invalid?" do
        subject { klass.new(:json, with_treasure) }
        its(:invalid?) { should be_false }
      end
    end

    describe "supports ActiveModel::Validation parameters" do
      context "format" do

        let(:valid) {
          class Valid
            include FirstResponder
            requires :foo, String, format: { with: /bar/ }
          end
        }

        let(:invalid) {
          class Invalid
            include FirstResponder
            requires :foo, String, format: { with: /baz/ }
          end
        }

        it "is invalid with non-matching format" do
          valid.new(:json, valid_json).should be_valid
          invalid.new(:json, valid_json).should_not be_valid
        end
      end
    end
  end

  describe "edge cases" do
    let(:json_array) { '[ { "foo": "bar" }, { "foo": "baz"} ]' }
    before do
      class Foo
        include Virtus.model
        attribute :foo, String
      end

      class JsonArrayTest
        include FirstResponder
        requires :foos, Array[Foo], at: ""
      end
    end
    subject { JsonArrayTest.new(:json, json_array).foos }
    it { should be_a_kind_of Array }
    it "coerces to Foo" do
      subject.first.should be_a Foo
    end
  end
end
