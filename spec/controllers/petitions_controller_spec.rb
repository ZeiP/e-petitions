require 'rails_helper'

RSpec.describe PetitionsController, type: :controller do
  context "With logged in user" do

    let(:user) { FactoryBot.build(:user) }

    before { allow(controller).to receive(:current_user).and_return(user) }
    
    describe "GET /petitions/new" do
      it "should assign a petition creator" do
        get :new
        expect(assigns[:new_petition]).not_to be_nil
      end

      it "is on stage 'petition'" do
        get :new
        expect(assigns[:new_petition].stage).to eq "petition";
      end

      it "fills in the action if given as query parameter 'q'" do
        get :new, params: { q: "my fancy new action" }
        expect(assigns[:new_petition].action).to eq("my fancy new action")
      end
    end

    describe "POST /petitions/new" do
      let(:params) do
        {
          action: "Save the planet",
          background: "Limit temperature rise at two degrees",
          additional_details: "Global warming is upon us",
          name: "John Mcenroe", email: "john@example.com",
          postcode: "SE3 4LL", location_code: "GB",
          uk_citizenship: "1"
        }
      end

      context "valid post" do
        let(:petition) { Petition.find_by_action("Save the planet") }

        it "should successfully create a new petition and a signature" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params }
          end

          expect(petition.creator).not_to be_nil
          expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/thank-you")
        end

        it "should successfully create a new petition and a signature even when email has white space either end" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(email: " john@example.com ") }
          end

          expect(petition).not_to be_nil
          expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/thank-you")
        end

        it "should strip a petition action on petition creation" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(action: " Save the planet") }
          end

          expect(petition).not_to be_nil
          expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/thank-you")
        end

        it "should send gather sponsors email to petition's creator" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params }
          end

          expect(last_email_sent).to deliver_to(user.email)
          expect(last_email_sent).to deliver_from(%{"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>})
          expect(last_email_sent).to have_subject("Action required: Petition “Save the planet”")
        end

        it "should successfully point the signature at the petition" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params }
          end

          expect(petition.creator.petition).to eq(petition)
        end

        it "should set user's ip address on signature" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params }
          end

          expect(petition.creator.ip_address).to eq("0.0.0.0")
        end

        it "should not be able to set the state of a new petition" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Petition::VALIDATED_STATE) }
          end

          expect(petition.state).to eq(Petition::PENDING_STATE)
        end

        it "should not be able to set the state of a new signature" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
          end

          expect(petition.creator.state).to eq(Signature::PENDING_STATE)
        end

        it "should set notify_by_email to false on the creator signature" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
          end

          expect(petition.creator.notify_by_email).to be_falsey
        end

        context "invalid post" do
          it "should not create a new petition if no action is given" do
            perform_enqueued_jobs do
              post :create, params: { stage: "replay_email", petition_creator: params.merge(action: "") }
            end

            expect(petition).to be_nil
            expect(assigns[:new_petition].errors[:action]).not_to be_blank
            expect(response).to be_successful
          end

          it "has stage of 'petition' if there is an error on action" do
            perform_enqueued_jobs do
              post :create, params: { stage: "replay_email", petition_creator: params.merge(action: "") }
            end

            expect(assigns[:new_petition].stage).to eq "petition"
          end

          it "has stage of 'petition' if there is an error on background" do
            perform_enqueued_jobs do
              post :create, params: { stage: "replay_email", petition_creator: params.merge(background: "") }
            end

            expect(assigns[:new_petition].stage).to eq "petition"
          end

          it "has stage of 'petition' if there is an error on additional_details" do
            perform_enqueued_jobs do
              post :create, params: { stage: "replay_email", petition_creator: params.merge(additional_details: "a" * 801) }
            end

            expect(assigns[:new_petition].stage).to eq "petition"
          end

        end
      end
    end

    describe "GET /petitions/:id" do
      let(:petition) { double }

      it "assigns the given petition" do
        allow(petition).to receive(:stopped?).and_return(false)
        allow(petition).to receive(:collecting_sponsors?).and_return(false)
        allow(petition).to receive(:in_moderation?).and_return(false)
        allow(petition).to receive(:moderated?).and_return(true)
        allow(Petition).to receive_message_chain(:show, find: petition)

        get :show, params: { id: 1 }
        expect(assigns(:petition)).to eq(petition)
      end

      it "does not allow hidden petitions to be shown" do
        expect {
          allow(Petition).to receive_message_chain(:visible, :find).and_raise ActiveRecord::RecordNotFound
          get :show, params: { id: 1 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "does not allow stopped petitions to be shown" do
        allow(petition).to receive(:stopped?).and_return(true)
        allow(petition).to receive(:collecting_sponsors?).and_return(false)
        allow(petition).to receive(:in_moderation?).and_return(false)
        allow(petition).to receive(:moderated?).and_return(false)
        allow(Petition).to receive_message_chain(:show, find: petition)

        get :show, params: { id: 1 }
        expect(response).to redirect_to "https://petition.parliament.uk/"
      end

      context "when the petition is archived" do
        let!(:petition) { FactoryBot.create(:closed_petition, archived_at: 1.hour.ago) }
        let!(:archived_petition) { FactoryBot.create(:archived_petition, id: petition.id, parliament: parliament) }

        context "and the parliament is not archived" do
          let!(:parliament) { FactoryBot.create(:parliament, archived_at: nil) }

          it "assigns the given petition" do
            get :show, params: { id: petition.id }
            expect(assigns(:petition)).to eq(petition)
          end
        end

        context "and the parliament is archived" do
          let(:parliament) { FactoryBot.create(:parliament, archived_at: 1.hour.ago) }

          it "redirects to the archived petition page" do
            get :show, params: { id: petition.id }
            expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions/#{petition.id}"
          end
        end
      end
    end

    describe "GET /petitions" do
      context "when no state param is provided" do
        it "is successful" do
          get :index
          expect(response).to be_successful
        end

        it "exposes a search scoped to the all facet" do
          get :index
          expect(assigns(:petitions).scope).to eq :all
        end
      end

      context "when a state param is provided" do
        context "but it is not a public facet from the locale file" do
          it "redirects to itself with state=all" do
            get :index, params: { state: "awaiting_monkey" }
            expect(response).to redirect_to "https://petition.parliament.uk/petitions?state=all"
          end

          it "preserves other params when it redirects" do
            get :index, params: { q: "what is clocks", state: "awaiting_monkey" }
            expect(response).to redirect_to "https://petition.parliament.uk/petitions?q=what+is+clocks&state=all"
          end
        end

        context "and it is a public facet from the locale file" do
          it "is successful" do
            get :index, params: { state: "open" }
            expect(response).to be_successful
          end

          it "exposes a search scoped to the state param" do
            get :index, params: { state: "open" }
            expect(assigns(:petitions).scope).to eq :open
          end
        end
      end
    end

    describe "GET /petitions/check" do
      it "is successful" do
        get :check
        expect(response).to be_successful
      end
    end

    describe "GET /petitions/check_results" do
      it "is successful" do
        get :check_results, params: { q: "action" }
        expect(response).to be_successful
      end
    end
  end
end
