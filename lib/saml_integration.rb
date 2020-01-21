module SamlIntegration

  class SamlConfigurationError < StandardError; end

  @saml_configuration = nil

  def self.url_for_sso
    configuration = get_saml_configuration
    raise SamlConfigurationError unless configuration
    request = OneLogin::RubySaml::Authrequest.new
    request.create(configuration)
  end

  def self.parse_acs(params)
    configuration = get_saml_configuration
    return OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: configuration)
  end

  def self.metadata
    configuration = get_saml_configuration
    meta = OneLogin::RubySaml::Metadata.new
    return meta.generate(configuration, true)
  end

  private

  def self.get_saml_configuration
    if !@saml_configuration
      idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
      settings = idp_metadata_parser.parse_remote(ENV['SAML_IDP_METADATA_URL'])
      settings.assertion_consumer_service_url = ENV['SAML_ACS_URL']
      settings.assertion_consumer_logout_service_url = ENV['SAML_LOGOUT_URL']
      settings.issuer = ENV['SAML_ISSUER']
      @saml_configuration = settings
    end
    return @saml_configuration
  end
end