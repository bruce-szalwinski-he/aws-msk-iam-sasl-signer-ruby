# frozen_string_literal: true

require "aws-sdk-kafka"
require "aws-sigv4"
require "base64"
require "uri"

module Aws::Msk::Iam::Sasl::Signer

  class MSKTokenProvider
    ENDPOINT_URL_TEMPLATE = "kafka.{}.amazonaws.com".freeze
    DEFAULT_TOKEN_EXPIRY_SECONDS = 900
    LIB_NAME = "aws-msk-iam-sasl-signer-ruby".freeze
    USER_AGENT_KEY = "User-Agent".freeze

    def initialize(region:)
      @region = region
    end

    def generate_auth_token
      credentials = load_default_credentials
      url = presign(credentials, endpoint_url)
      [urlsafe_encode64(user_agent(url)), expiration_time_ms(url)]
    end

    private

    def load_default_credentials
      Credentials.new.load_default_credentials
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
  end
end
