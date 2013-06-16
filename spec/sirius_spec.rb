require 'sirius'
require 'json'

describe Sirius do
  describe ".initialize" do
    let(:klass) { class Test; include Sirius; end }

    context 'with unknown format' do
      it "raises UnknownSerializationFormat error" do
        expect{ klass.new(:wrong, '') }.to raise_error
      end
    end


  end
end
