require 'onelogin/ruby-saml'
require 'saml_integration'

class SamlController < ApplicationController

  skip_before_action :authenticate, only: [:acs, :logout, :sso]
  skip_before_action :verify_authenticity_token, only: [:acs, :logout]

  def sso
    redirect_to(SamlIntegration.url_for_sso)
  end

  def acs
    response = SamlIntegration.parse_acs(params)
    params = response.attributes.attributes
    @user_session = UserSession.new(email: params['email'][0], username: params['membernumber'][0])
    if @user_session.save
      render json: @user_session
    else

    end
  end

  def metadata
    render xml: SamlIntegration.metadata, content_type: 'application/xml'
  end

  def logout
  end
end