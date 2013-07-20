require 'first_responder'

describe FirstResponder do
  context "dependencies" do
    it 'requires virtus' do
      Virtus.should be
    end
    it 'requires active_model' do
      ActiveModel.should be
    end
  end
end
