require 'onelogin/ruby-saml'
require 'saml_integration'

class SamlController < ApplicationController

  skip_before_action :authenticate, only: [:acs, :logout, :sso]
  skip_before_action :verify_authenticity_token, only: [:acs, :logout]

  def sso
    if Rails.env.development?
      sign_in({'email' => ['leif.setala@trineria.fi'], 'membernumber' => ['1234356']})
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
    response = SamlIntegration.parse_slo(params)
    current_session.destroy if current_session
    redirect_to '/'
  end

  def application_logout
    if Rails.env.development?
      current_session.destroy if current_session
      redirect_to '/'
    else
      redirect_to(SamlIntegration.url_for_slo)
    end
  end

  private

  def sign_in(params)
    if logged_in?
      redirect_to home_url
    else
      user = User.find_or_initialize_by(email: params['email'][0], username: params['membernumber'][0])
      user.assign_attributes(firstname: params['firstname'][0], lastname: params['lastname'][0])
      if user.save
        @current_session = UserSession.create(user, false)
        redirect_to home_url
      else
        raise "#{user.errors.full_messages}"
      end
    end
  end
end