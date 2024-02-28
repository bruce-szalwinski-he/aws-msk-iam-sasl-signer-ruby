require "test_helper"
require "aws-sdk-kafka"
require "aws-sdk-sts"
require "base64"
require "capture"

class TestCredentialsProvider
  include Aws::CredentialProvider
  def initialize
    @credentials = Aws::Credentials.new(
      "access_key_id",
      "secret_access_key",
      "session_token"
    )
  end

  attr_reader :credentials
end

class AwsMskIamSaslSigner::MskTokenProviderTest < Minitest::Test
  def setup
    @token_provider = AwsMskIamSaslSigner::MSKTokenProvider.new(region: "us-east-1")
    @creds = Aws::Credentials.new("access_key_id", "secret_access", "session_token")
  end

  def test_generate_auth_token
    AwsMskIamSaslSigner::CredentialsResolver.stub_any_instance :from_credential_provider_chain, @creds do
      assert_token(@token_provider.generate_auth_token)
    end
  end

  def test_generate_auth_token_with_aws_debug
    AwsMskIamSaslSigner::CredentialsResolver.stub_any_instance :from_credential_provider_chain, @creds do
      Aws::STS::Client.stub :new, Aws::STS::Client.new(stub_responses: true) do
        auth_token = @token_provider.generate_auth_token(aws_debug: true)
        refute_nil auth_token.caller_identity
        assert_kind_of AwsMskIamSaslSigner::MSKTokenProvider::CallerIdentity, auth_token.caller_identity
      end
    end
  end

  def test_generate_auth_token_from_profile
    AwsMskIamSaslSigner::CredentialsResolver.stub_any_instance :from_profile, @creds do
      assert_token(@token_provider.generate_auth_token_from_profile("test-profile"))
    end
  end

  def test_generate_auth_token_from_role_arn
    AwsMskIamSaslSigner::CredentialsResolver.stub_any_instance :from_role_arn, @creds do
      assert_token(@token_provider.generate_auth_token_from_role_arn("role_arn"))
    end
  end

  def test_generate_auth_token_from_credentials_provider
    assert_token(
      @token_provider.generate_auth_token_from_credentials_provider(
        TestCredentialsProvider.new
      )
    )
  end

  private

  def assert_token(auth_token)
    decoded_signed_url, params = parse_url(auth_token.token)

    assert_url(decoded_signed_url)
    assert_query_parameters(params)
    assert_credentials(params)
    assert_expiration_time_ms(params, auth_token.expiration_time_ms)
  end

  def parse_url(signed_url)
    decoded_signed_url = Base64.urlsafe_decode64(signed_url)
    uri = URI.parse(decoded_signed_url)
    params = URI.decode_www_form(String(uri.query))
    params = params.group_by(&:first).transform_values { |a| a.map(&:last) }
    [decoded_signed_url, params]
  end

  def assert_url(decoded_signed_url)
    assert_match "https://kafka.us-east-1.amazonaws.com/?Action=kafka-cluster%3AConnect", decoded_signed_url
  end

  def assert_query_parameters(params)
    assert_equal "kafka-cluster:Connect", params["Action"][0]
    assert_equal "AWS4-HMAC-SHA256", params["X-Amz-Algorithm"][0]
    assert_equal "session_token", params["X-Amz-Security-Token"][0]
    assert_equal "host", params["X-Amz-SignedHeaders"][0]
    assert_equal "900", params["X-Amz-Expires"][0]
    assert_match "aws-msk-iam-sasl-signer-msk-iam-sasl-signer-ruby", params["User-Agent"][0]
  end

  def assert_credentials(params)
    credentials = params["X-Amz-Credential"][0]
    split_credentials = credentials.split("/")
    assert_equal "access_key_id", split_credentials[0]
    assert_equal "us-east-1", split_credentials[2]
    assert_equal "kafka-cluster", split_credentials[3]
    assert_equal "aws4_request", split_credentials[4]
  end

  def assert_expiration_time_ms(params, expiration_time_ms)
    date_obj = DateTime.strptime(params["X-Amz-Date"][0], "%Y%m%dT%H%M%SZ")
    current_time = Time.now.utc.to_i
    assert_lte date_obj.to_time.to_i, current_time

    actual_expires = 1000 * (params["X-Amz-Expires"][0].to_i + date_obj.to_time.to_i)
    assert_equal expiration_time_ms, actual_expires
  end
end
