require 'onelogin/ruby-saml'
require 'saml_integration'

class SamlController < ApplicationController

  skip_before_action :authenticate, only: [:acs, :logout, :sso]

  def sso
    redirect_to(SamlIntegration.url_for_sso)
  end

  def acs
    response = SamlIntegration.parse_acs(params)
    if response.valid?
      Rails.logger.warn response.inspect
    end
  end

  def metadata
    render xml: SamlIntegration.metadata
  end

  def logout
  end
end