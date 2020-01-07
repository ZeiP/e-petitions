require 'rails_helper'

RSpec.describe SponsorsController, type: :controller do
  before do
    constituency = FactoryBot.create(:constituency, :london_and_westminster)
    allow(Constituency).to receive(:find_by_postcode).with("SW1A1AA").and_return(constituency)
  end

  describe "GET /petitions/:petition_id/sponsors/new" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :new, params: { petition_id: 1, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :new, params: { petition_id: petition.id, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the creator's signature has not been validated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:creator) { petition.creator }

      it "validates the creator's signature" do
        expect {
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        }.to change {
          creator.reload.validated?
        }.from(false).to(true)
      end
    end

    %w[flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:current_time) { Time.utc(2019, 4, 18, 6, 0, 0) }

        around do |example|
          travel_to(current_time) { example.run }
        end

        before do
          allow(Authlogic::Random).to receive(:friendly_token).and_return("D8MxrkwNexP1NgxpZq")

          session[:form_requests] = {
            "100000" => {
              "form_token" => "jcr0DcYQXio18qKDBGw",
              "form_requested_at" => "2019-04-16T06:00:00Z"
            },
            "100001" => {
              "form_token" => "G0WnZSxal6vmZkFYnzY",
              "form_requested_at" => "2019-04-18T04:00:00Z"
            }
          }

          cookies.encrypted["jcr0DcYQXio18qKDBGw"] = "2019-04-16T06:00:00Z"
          cookies.encrypted["G0WnZSxal6vmZkFYnzY"] = "2019-04-18T04:00:00Z"

          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable with a new signature" do
          expect(assigns[:signature]).not_to be_persisted
        end

        it "sets the signature's location_code to 'GB'" do
          expect(assigns[:signature].location_code).to eq("GB")
        end

        it "sets the form token and requested at details in the session" do
          expect(session[:form_requests]).to match(a_hash_including(
            "#{petition.id}" => {
              "form_token" => "D8MxrkwNexP1NgxpZq",
              "form_requested_at" => "2019-04-18T06:00:00Z"
            }
          ))
        end

        it "sets the signature's form token to the one in the session" do
          expect(assigns[:signature].form_token).to eq("D8MxrkwNexP1NgxpZq")
        end

        it "sets the signature's form requested at timestamp to the one in the session" do
          expect(assigns[:signature].form_requested_at).to eq("2019-04-18T06:00:00Z".in_time_zone)
        end

        it "expires old form requests" do
          expect(session[:form_requests]["100000"]).to be_nil
          expect(response.cookies).to have_key("jcr0DcYQXio18qKDBGw")
          expect(response.cookies["jcr0DcYQXio18qKDBGw"]).to be_nil
        end

        it "leaves current form request untouched" do
          expect(session[:form_requests]["100001"]["form_token"]).to eq("G0WnZSxal6vmZkFYnzY")
          expect(session[:form_requests]["100001"]["form_requested_at"]).to eq("2019-04-18T04:00:00Z")
          expect(cookies.encrypted["G0WnZSxal6vmZkFYnzY"]).to eq("2019-04-18T04:00:00Z")
          expect(response.cookies).not_to have_key("G0WnZSxal6vmZkFYnzY")
        end

        it "renders the sponsors/new template" do
          expect(response).to render_template("sponsors/new")
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end
      end
    end
  end

  describe "POST /petitions/:petition_id/sponsors/new" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        uk_citizenship: "1",
        postcode: "SW1A 1AA",
        location_code: "GB"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :confirm, params: { petition_id: 1, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :confirm, params: { petition_id: petition.id, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :confirm, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :confirm, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:current_time) { Time.utc(2019, 4, 18, 6, 0, 30) }

        around do |example|
          travel_to(current_time) { example.run }
        end

        before do
          session[:form_requests] = {
            "#{petition.id}" => {
              "form_token" => "wYonHKjTeW7mtTusqDv",
              "form_requested_at" => "2019-04-18T06:00:00Z"
            }
          }

          post :confirm, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable with a new signature" do
          expect(assigns[:signature]).not_to be_persisted
        end

        it "sets the signature's params" do
          expect(assigns[:signature].name).to eq("Ted Berry")
          expect(assigns[:signature].email).to eq("ted@example.com")
          expect(assigns[:signature].uk_citizenship).to eq("1")
          expect(assigns[:signature].postcode).to eq("SW1A1AA")
          expect(assigns[:signature].location_code).to eq("GB")
          expect(assigns[:signature].form_token).to eq("wYonHKjTeW7mtTusqDv")
          expect(assigns[:signature].form_requested_at).to eq("2019-04-18T06:00:00Z".in_time_zone)
        end

        it "records the IP address on the signature" do
          expect(assigns[:signature].ip_address).to eq("0.0.0.0")
        end

        it "renders the sponsors/confirm template" do
          expect(response).to render_template("sponsors/confirm")
        end

        context "and the params are invalid" do
          let(:params) do
            {
              name: "Ted Berry",
              email: "",
              uk_citizenship: "1",
              postcode: "12345",
              location_code: "GB"
            }
          end

          it "renders the sponsors/new template" do
            expect(response).to render_template("sponsors/new")
          end
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end
      end
    end
  end

  describe "POST /petitions/:petition_id/sponsors" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        uk_citizenship: "1",
        postcode: "SW1A 1AA",
        location_code: "GB"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :create, params: { petition_id: 1, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :create, params: { petition_id: petition.id, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:current_time) { Time.utc(2019, 4, 18, 6, 1, 0) }

        around do |example|
          travel_to(current_time) { example.run }
        end

        context "and the signature is not a duplicate" do
          before do
            cookies.encrypted["wYonHKjTeW7mtTusqDv"] = "2019-04-18T06:00:00Z"

            session[:form_requests] = {
              "#{petition.id}" => {
                "form_token" => "wYonHKjTeW7mtTusqDv",
                "form_requested_at" => "2019-04-18T06:00:00Z"
              }
            }

            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable with a saved signature" do
            expect(assigns[:signature]).to be_persisted
          end

          it "sets the signature's params" do
            expect(assigns[:signature].name).to eq("Ted Berry")
            expect(assigns[:signature].email).to eq("ted@example.com")
            expect(assigns[:signature].uk_citizenship).to eq("1")
            expect(assigns[:signature].postcode).to eq("SW1A1AA")
            expect(assigns[:signature].location_code).to eq("GB")
            expect(assigns[:signature].form_token).to eq("wYonHKjTeW7mtTusqDv")
            expect(assigns[:signature].form_requested_at).to eq("2019-04-18T06:00:00Z".in_time_zone)
            expect(assigns[:signature].image_loaded_at).to eq("2019-04-18T06:00:00Z".in_time_zone)
          end

          it "records the IP address on the signature" do
            expect(assigns[:signature].ip_address).to eq("0.0.0.0")
          end

          it "sends a confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Please confirm your email address")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end

          it "deletes the form request details" do
            expect(response.cookies).to have_key("wYonHKjTeW7mtTusqDv")
            expect(response.cookies["wYonHKjTeW7mtTusqDv"]).to be_nil
            expect(session[:form_requests]["#{petition.id}"]).to be_nil
          end

          context "and the params are invalid" do
            let(:params) do
              {
                name: "Ted Berry",
                email: "",
                uk_citizenship: "1",
                postcode: "SW1A 1AA",
                location_code: "GB"
              }
            end

            it "renders the sponsors/new template" do
              expect(response).to render_template("sponsors/new")
            end
          end
        end

        context "and the signature is a pending duplicate" do
          let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable to the original signature" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "re-sends the confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Please confirm your email address")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a pending duplicate alias" do
          let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

          before do
            allow(Site).to receive(:disable_plus_address_check?).and_return(true)

            perform_enqueued_jobs {
              post :create, petition_id: petition.id, token: petition.sponsor_token, signature: params.merge(email: "ted+petitions@example.com")
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable to the original signature" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "re-sends the confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Please confirm your email address")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a validated duplicate" do
          let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable to the original signature" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "sends a duplicate signature email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Duplicate signature of petition")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a validated duplicate alias" do
          let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

          before do
            allow(Site).to receive(:disable_plus_address_check?).and_return(true)

            perform_enqueued_jobs {
              post :create, petition_id: petition.id, token: petition.sponsor_token, signature: params.merge(email: "ted+petitions@example.com")
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable to the original signature" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "sends a duplicate signature email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Duplicate signature of petition")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end
      end
    end
  end

  describe "GET /petitions/:petition_id/signatures/thank-you" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :thank_you, params: { petition_id: 1, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :thank_you, params: { petition_id: petition.id, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "doesn't redirect to the petition page" do
          expect(response).not_to redirect_to("/petitions/#{petition.id}")
        end

        it "renders the signatures/thank_you template" do
          expect(response).to render_template("signatures/thank_you")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

        before do
          get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "renders the signatures/thank_you template" do
          expect(response).to render_template("signatures/thank_you")
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end

          it "renders the signatures/thank_you template" do
            expect(response).to render_template("signatures/thank_you")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end

          it "renders the signatures/thank_you template" do
            expect(response).to render_template("signatures/thank_you")
          end
        end
      end
    end
  end

  describe "GET /sponsors/:id/verify" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    %w[flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :verify, params: { id: signature.id, token: signature.perishable_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        before do
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        end

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    context "when the petition is pending" do
      let(:petition) { FactoryBot.create(:pending_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        session[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "validates the signature" do
        expect(assigns[:signature]).to be_validated
      end

      it "validates the creator" do
        expect(petition.creator.reload).to be_validated
      end

      it "changes the petition state to validated" do
        expect(petition.reload).to be_validated
      end

      it "records the constituency id on the signature" do
        expect(assigns[:signature].constituency_id).to eq("3415")
      end

      it "records the ip address on the signature" do
        expect(assigns[:signature].validated_ip).to eq("0.0.0.0")
      end

      it "deletes old signed tokens" do
        expect(session[:signed_tokens]).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the session" do
        expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "sends email notification to the petition creator" do
        expect(last_email_sent).to deliver_to("bob@example.com")
        expect(last_email_sent).to have_subject("Alice supported your petition")
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end
      end
    end

    context "when the petition is validated" do
      let(:petition) { FactoryBot.create(:validated_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        session[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "validates the signature" do
        expect(assigns[:signature]).to be_validated
      end

      it "records the constituency id on the signature" do
        expect(assigns[:signature].constituency_id).to eq("3415")
      end

      it "records the ip address on the signature" do
        expect(assigns[:signature].validated_ip).to eq("0.0.0.0")
      end

      it "deletes old signed tokens" do
        expect(session[:signed_tokens]).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the session" do
        expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "sends email notification to the petition creator" do
        expect(last_email_sent).to deliver_to("bob@example.com")
        expect(last_email_sent).to have_subject("Alice supported your petition")
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end

        it "doesn't send another email" do
          expect(deliveries).to be_empty
        end
      end

      context "and the signature has been validated more than 15 minutes ago" do
        let(:signature) { FactoryBot.create(:validated_signature, validated_at: 30.minutes.ago, petition: petition, sponsor: true) }

        it "redirects to the new sponsor page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}")
        end
      end

      context "and is at the threshold for moderation" do
        let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: Site.minimum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "validates the signature" do
          expect(assigns[:signature]).to be_validated
        end

        it "records the constituency id on the signature" do
          expect(assigns[:signature].constituency_id).to eq("3415")
        end

        it "saves the signed token in the session" do
          expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "sends email notification to the petition creator" do
          expect(last_email_sent).to deliver_to("bob@example.com")
          expect(last_email_sent).to have_subject("We’re checking your petition")
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has one remaining sponsor slot" do
        let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "validates the signature" do
          expect(assigns[:signature]).to be_validated
        end

        it "records the constituency id on the signature" do
          expect(assigns[:signature].constituency_id).to eq("3415")
        end

        it "saves the signed token in the session" do
          expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "sends email notification to the petition creator" do
          expect(last_email_sent).to deliver_to("bob@example.com")
          expect(last_email_sent).to have_subject("We’re checking your petition")
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has reached the maximum number of sponsors" do
        let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

        it "redirects to the petition moderation info page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
        end
      end
    end

    context "when the petition is sponsored" do
      let(:petition) { FactoryBot.create(:sponsored_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        session[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "validates the signature" do
        expect(assigns[:signature]).to be_validated
      end

      it "records the constituency id on the signature" do
        expect(assigns[:signature].constituency_id).to eq("3415")
      end

      it "records the ip address on the signature" do
        expect(assigns[:signature].validated_ip).to eq("0.0.0.0")
      end

      it "deletes old signed tokens" do
        expect(session[:signed_tokens]).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the session" do
        expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "doesn't send an email notification to the petition creator" do
        expect(deliveries).to be_empty
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end
      end

      context "and has one remaining sponsor slot" do
        let(:petition) { FactoryBot.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "validates the signature" do
          expect(assigns[:signature]).to be_validated
        end

        it "records the constituency id on the signature" do
          expect(assigns[:signature].constituency_id).to eq("3415")
        end

        it "saves the signed token in the session" do
          expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "doesn't send an email notification to the petition creator" do
          expect(deliveries).to be_empty
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has reached the maximum number of sponsors" do
        let(:petition) { FactoryBot.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

        it "redirects to the petition moderation info page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
        end
      end
    end
  end

  describe "GET /sponsors/:id/sponsored" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: 1 }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signed token is missing" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

      it "redirects to the petition moderation info page" do
        get :signed, params: { id: signature.id }
        expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id }
        }.not_to raise_error
      end
    end

    %w[flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :signed, params: { id: signature.id }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        before do
          session[:signed_tokens] = { signature.id.to_s => signature.signed_token }
          get :signed, params: { id: signature.id }
        end

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "doesn't redirect to the petition page" do
          expect(response).not_to redirect_to("/petitions/#{petition.id}")
        end

        it "renders the sponsors/signed template" do
          expect(response).to render_template("sponsors/signed")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        context "when the signature has been validated" do
          before do
            session[:signed_tokens] = { signature.id.to_s => signature.signed_token }
            get :signed, params: { id: signature.id }
          end

          it "assigns the @signature instance variable" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "marks the signature has having seen the confirmation page" do
            expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
          end

          it "renders the sponsors/signed template" do
            expect(response).to render_template("sponsors/signed")
          end

          it "deletes the signed token from the session" do
            expect(session[:signed_tokens]).to be_empty
          end

          context "and the signature has already seen the confirmation page" do
            let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 2, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "marks the signature has having seen the confirmation page" do
              expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "marks the signature has having seen the confirmation page" do
              expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end
        end

        context "when the signature has not been validated" do
          let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

          before do
            get :signed, params: { id: signature.id }
          end

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end
      end
    end
  end
end
