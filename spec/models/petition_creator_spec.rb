require 'rails_helper'
require_relative 'taggable_examples'

RSpec.describe PetitionCreator, type: :model do
  context "methods" do
    context "save" do
      let(:params) do
        {
          action: SecureRandom.uuid,
          background: "Limit temperature rise at two degrees",
          additional_details: "Global warming is upon us",
          name: "John Mcenroe", email: "john@example.com",
          postcode: "SE3 4LL", location_code: "GB",
          uk_citizenship: "1"
        }
      end

      let(:mock_request) do
        double(remote_ip: "0.0.0.0")
      end

      it "creates a valid signature for the creator" do
        petition_creator = described_class.new(ActionController::Parameters.new({ petition_creator: params, stage: "creator" }), mock_request)
        petition_creator.save

        # This is a workaround to test against the correct petition since PetitionCreator doesn't actually return the created petition.
        # Because of this, we use a generated UUID as the action in order to retrieve the correct petition from db without knowing it's id
        # getting latest petition won't always work in case we run tests in parallel (or it might not work).
        petition = Petition.find_by_action(params[:action])
        expect(petition.signature_count).to eq(1)
      end
    end
  end
end