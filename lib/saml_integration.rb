module SamlIntegration

  class SamlConfigurationError < StandardError; end

  @saml_configuration = nil

  def self.url_for_sso
    configuration = get_saml_configuration
    raise SamlConfigurationError unless configuration
    request = OneLogin::RubySaml::Authrequest.new
    request.create(configuration)
  end

  def parse_acs(params)
    configuration = get_saml_configuration
    return OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: configuration)
  end

  private

  def self.get_saml_configuration
    @saml_configuration = @saml_configuration || OneLogin::RubySaml::Settings.new({
      assertion_consumer_service_url: ENV['SAML_ACS_URL'],
      assertion_consumer_logout_service_url: ENV['SAML_LOGOUT_URL'],
      idp_sso_target_url: ENV['SAML_IDP_SSO_TARGET_URL']
    })
    return @saml_configuration
  end
end