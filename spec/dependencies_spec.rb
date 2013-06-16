require 'sirius'

describe Sirius do
  context "dependencies" do
    it 'requires virtus' do
      Virtus.should be
    end
    it 'requires aequitas' do
      Aequitas.should be
    end
  end
end
