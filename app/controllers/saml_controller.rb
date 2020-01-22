require 'onelogin/ruby-saml'
require 'saml_integration'

class SamlController < ApplicationController

  skip_before_action :authenticate, only: [:acs, :logout, :sso]
  skip_before_action :verify_authenticity_token, only: [:acs, :logout]

  def sso
    if Rails.env.development?
      sign_in({'email': ['leif.setala@trineria.fi'], 'membernumber': ['1234356']})
    else
      redirect_to(SamlIntegration.url_for_sso)
    end
  end

  def acs
    response = SamlIntegration.parse_acs(params)
    params = response.attributes.attributes
    sign_in(params)
  end

  def metadata
    render xml: SamlIntegration.metadata, content_type: 'application/xml'
  end

  def logout
  end

  def application_logout
    redirect_to(SamlIntegration.url_for_slo)
  end

  private

  def sign_in(params)
    user = User.find_or_initialize_by(email: params[:email][0], username: params[:membernumber][0])
    if user.save
      redirect_to home_url
    else
      raise "#{user.errors.full_messages}"
    end
  end
end