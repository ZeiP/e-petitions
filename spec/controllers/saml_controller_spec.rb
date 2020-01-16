require 'rails_helper'
require 'saml_integration'

RSpec.describe SamlController, type: :controller do
  context 'With valid SAML settings' do
    context '#partio_id_sso' do
      it 'Redirects to sso url' do
        get :sso
        expect(response.location).to match(ENV['SAML_IDP_SSO_TARGET_URL'])
      end
    end
  end

  context 'Without valid SAML settings' do
    before do
      expect(SamlIntegration).to receive(:get_saml_configuration).and_return(nil)
    end

    context '#partio_id_sso' do
      it 'Should throw a SamlConfigurationError' do
        expect {
          get :sso
        }.to raise_error(SamlIntegration::SamlConfigurationError)
      end
    end
  end
end