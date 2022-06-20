require "rails_helper"

RSpec.describe AdminMailer, type: :mailer do
    let :creator do
        FactoryBot.build(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com", creator: true)
    end

    let :petition do
        FactoryBot.create(:pending_petition,
          creator: creator,
          action: "Allow organic vegetable vans to use red diesel",
          background: "Add vans to permitted users of red diesel",
          additional_details: "To promote organic vegetables"
        )
    end

    let(:pending_signature) { FactoryBot.create(:pending_signature, petition: petition) }
    let(:validated_signature) { FactoryBot.create(:validated_signature, petition: petition) }
  
    describe "notify_admin_of_petition_created" do
      let(:mail) { AdminMailer.notify_admin_of_petition_created(petition) }

      before do
        petition.save
      end

      it "is sent to right address" do
        expect(mail.to).to eq(%w[partiolaisaloite@partio.fi])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end
      
      it "has right subject" do
        expect(mail).to have_subject("Petition created")
      end

      it "notifies admin of petition created" do
        expect(mail).to have_body_text("You are receiving this email because a petition was recently created")
      end
    end
end