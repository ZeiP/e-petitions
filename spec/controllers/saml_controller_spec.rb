require 'rails_helper'
require 'saml_integration'
require 'ostruct'

RSpec.describe SamlController, type: :controller do
  context 'With valid SAML settings' do
    before do
      expect(SamlIntegration).to receive(:get_saml_configuration).and_return(
        OneLogin::RubySaml::Settings.new(
          {
            idp_sso_target_url: ENV['SAML_IDP_SSO_TARGET_URL'],
            idp_slo_target_url: ENV['SAML_IDP_SLO_TARGET_URL']
          }
        )
      )
    end
    context '#sso' do
      it 'Redirects to sso url' do
        get :sso
        expect(response.location).to match(ENV['SAML_IDP_SSO_TARGET_URL'])
      end
    end

    context '#application_logout' do
      it 'Redirects to logout url' do
        get :application_logout
        expect(response.location).to match(ENV['SAML_IDP_SLO_TARGET_URL'])
      end
    end
  end

  context 'Without valid SAML settings' do
    before do
      expect(SamlIntegration).to receive(:get_saml_configuration).and_return(nil)
    end

    context '#sso' do
      it 'Should throw a SamlConfigurationError' do
        expect {
          get :sso
        }.to raise_error(SamlIntegration::SamlConfigurationError)
      end
    end
  end

  context 'User creation' do
    context '#acs' do
      it 'Searches for existing users only by username and updates attributes' do
        samlParams = OpenStruct.new(
          :attributes => OpenStruct.new(
            :attributes => {
              "membernumber" => ['foo'],
              "firstname" => ['John'],
              "lastname" => ['Doe'],
              "email" => ['john.doe@example.com']
            }
          )
        )
        allow(SamlIntegration).to receive(:parse_acs).and_return(samlParams)
        user = User.create(username: 'foo', email: 'jane.doe@example.com', firstname: 'Jane', lastname: 'Doe')
        get :acs
        user.reload
        expect(response.location).to match('https://petition.parliament.uk/?locale=en-GB')
        expect(user.email).to eq('john.doe@example.com')
        expect(user.firstname).to eq('John')
        expect(user.lastname).to eq('Doe')
        expect(user.username).to eq('foo')
      end
    end
  end
end