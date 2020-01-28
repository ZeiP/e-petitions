require 'rails_helper'
require 'saml_integration'

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
end