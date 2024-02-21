# frozen_string_literal: true

require "aws-sdk-kafka"
require "aws-sigv4"
require "base64"
require "uri"

module Aws::Msk::Iam::Sasl::Signer
  class MSKTokenProvider
    ENDPOINT_URL_TEMPLATE = "kafka.{}.amazonaws.com"
    DEFAULT_TOKEN_EXPIRY_SECONDS = 900
    LIB_NAME = "aws-msk-iam-sasl-signer-ruby"
    USER_AGENT_KEY = "User-Agent"
    SESSION_NAME = "MSKSASLDefaultSession"

    def initialize(region:)
      @region = region
    end

    def generate_auth_token(aws_debug: false)
      credentials = load_default_credentials
      log_caller_identity(credentials) if aws_debug
      url = presign(credentials, endpoint_url)
      [urlsafe_encode64(user_agent(url)), expiration_time_ms(url)]
    end

    def generate_auth_token_from_profile(profile)
      credentials = load_credentials_from_profile(profile)
      url = presign(credentials, endpoint_url)
      [urlsafe_encode64(user_agent(url)), expiration_time_ms(url)]
    end

    def generate_auth_token_from_role_arn(role_arn, session_name=nil)
      session_name ||= SESSION_NAME
      credentials = load_credentials_from_role_arn(role_arn, session_name)
      url = presign(credentials, endpoint_url)
      [urlsafe_encode64(user_agent(url)), expiration_time_ms(url)]
    end

    private

    def load_default_credentials
      Credentials.new.load_default_credentials
    end

    def load_credentials_from_profile(profile)
      credentials = Aws::SharedCredentials.new(profile_name: profile)
      credentials.credentials
    end

    def load_credentials_from_role_arn(role_arn, session_name)
      sts = Aws::STS::Client.new
      assumed_role = sts.assume_role({ role_arn: role_arn, role_session_name: session_name })
      assumed_role.credentials
    end

    def endpoint_url
      host = ENDPOINT_URL_TEMPLATE.gsub("{}", @region)
      query_params = {
        Action: "kafka-cluster:Connect"
      }
      URI::HTTPS.build(host: host, path: "/", query: URI.encode_www_form(query_params))
    end

    def presign(credentials, url)
      signer = Aws::Sigv4::Signer.new(
        service: "kafka-cluster",
        region: @region,
        credentials: credentials
      )
      signer.presign_url(
        http_method: "GET",
        url: url,
        expires_in: DEFAULT_TOKEN_EXPIRY_SECONDS
      )
    end

    def user_agent(url)
      new_query_ar = URI.decode_www_form(url.query) << [USER_AGENT_KEY, "#{LIB_NAME}/#{VERSION}"]
      url.query = URI.encode_www_form(new_query_ar)
      url.to_s
    end

    def urlsafe_encode64(url)
      Base64.urlsafe_encode64(url, padding: false)
    end

    def expiration_time_ms(url)
      params = URI.decode_www_form(String(url.query))
      signing_date = params.find { |param| param[0] == "X-Amz-Date" }
      signing_time = DateTime.strptime(signing_date[1], "%Y%m%dT%H%M%SZ")
      1000 * (signing_time.to_time.to_i + DEFAULT_TOKEN_EXPIRY_SECONDS)
    end

    def log_caller_identity(credentials)
      sts = Aws::STS::Client.new(
        access_key_id: credentials.access_key_id,
        secret_access_key: credentials.secret_access_key,
        session_token: credentials.session_token
      )
      caller_identity = sts.get_caller_identity
      puts "Credentials Identity:"
      puts "  UserId: #{caller_identity.user_id}"
      puts "  Account: #{caller_identity.account}"
      puts "  Arn: #{caller_identity.arn}}"
    end
  end
end
