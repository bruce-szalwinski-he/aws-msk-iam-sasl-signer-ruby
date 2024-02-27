require "test_helper"
require "aws-sdk-kafka"
require "aws-sdk-sts"
require "base64"
require "capture"

class TestCredentialProvider
  include Aws::CredentialProvider
  def initialize
    @credentials = Aws::Credentials.new("access_key_id", "secret_access_key")
  end

  attr_reader :credentials
end

class AwsMskIamSaslSigner::SignerTest < Minitest::Test
  def setup
    @token_provider = AwsMskIamSaslSigner::MSKTokenProvider.new(region: "us-east-1")
    @creds = Aws::Credentials.new("access_key_id", "secret_access", "session_token")
    AwsMskIamSaslSigner::CredentialsProviderResolver.stub_any_instance :from_credential_provider_chain, @creds do
      @signed_url, @expiration_time_ms = @token_provider.generate_auth_token
      @decoded_signed_url = Base64.urlsafe_decode64(@signed_url)
      uri = URI.parse(@decoded_signed_url)
      params = URI.decode_www_form(String(uri.query))
      @params = params.group_by(&:first).transform_values { |a| a.map(&:last) }
    end
  end

  def test_generate_auth_token_url
    assert_match "https://kafka.us-east-1.amazonaws.com/?Action=kafka-cluster%3AConnect", @decoded_signed_url
  end

  def test_generate_auth_token_query_parameters
    assert_equal "kafka-cluster:Connect", @params["Action"][0]
    assert_equal "AWS4-HMAC-SHA256", @params["X-Amz-Algorithm"][0]
    assert_equal "session_token", @params["X-Amz-Security-Token"][0]
    assert_equal "host", @params["X-Amz-SignedHeaders"][0]
    assert_equal "900", @params["X-Amz-Expires"][0]
    assert_match "aws-msk-iam-sasl-signer-msk-iam-sasl-signer-ruby", @params["User-Agent"][0]
  end

  def test_generate_auth_token_credentials
    credentials = @params["X-Amz-Credential"][0]
    split_credentials = credentials.split("/")
    assert_equal "access_key_id", split_credentials[0]
    assert_equal "us-east-1", split_credentials[2]
    assert_equal "kafka-cluster", split_credentials[3]
    assert_equal "aws4_request", split_credentials[4]
  end

  def test_generate_auth_token_expiration
    date_obj = DateTime.strptime(@params["X-Amz-Date"][0], "%Y%m%dT%H%M%SZ")
    current_time = Time.now.utc.to_i
    assert_lte date_obj.to_time.to_i, current_time

    actual_expires = 1000 * (@params["X-Amz-Expires"][0].to_i + date_obj.to_time.to_i)
    assert_equal @expiration_time_ms, actual_expires
  end

  def test_generate_auth_token_log_caller_identity
    stub = Aws::STS::Client.new(stub_responses: true)
    c = Capture.capture do
      AwsMskIamSaslSigner::CredentialsProviderResolver.stub_any_instance :from_credential_provider_chain, @creds do
        Aws::STS::Client.stub :new, stub do
          token_provider = AwsMskIamSaslSigner::MSKTokenProvider.new(region: "us-east-1")
          @signed_url, @expiration_time_ms = token_provider.generate_auth_token(aws_debug: true)
        end
      end
    end
    assert_match "Credentials Identity", c.stdout
  end

  def test_generate_auth_token_from_profile
    AwsMskIamSaslSigner::CredentialsProviderResolver.stub_any_instance :from_profile, @creds do
      token_provider = AwsMskIamSaslSigner::MSKTokenProvider.new(region: "us-east-1")
      @signed_url, @expiration_time_ms = token_provider.generate_auth_token_from_profile(profile: "default")
      refute_nil @signed_url
      refute_nil @expiration_time_ms
    end
  end

  def test_generate_auth_token_from_role_arn
    AwsMskIamSaslSigner::CredentialsProviderResolver.stub_any_instance :from_role_arn, @creds do
      @signed_url, @expiration_time_ms = @token_provider.generate_auth_token_from_role_arn(
        role_arn: "arn:aws-msk-iam-sasl-signer:iam::123456789012:role/role-name"
      )
      refute_nil @signed_url
      refute_nil @expiration_time_ms
    end
  end

  def test_generate_auth_token_invalid_credentials_provider
    token_provider = AwsMskIamSaslSigner::MSKTokenProvider.new(region: "us-east-1")
    assert_raises(RuntimeError) do
      token_provider.generate_auth_token_from_credentials_provider("invalid")
    end
  end

  def test_generate_auth_token_valid_credentials_provider
    @signed_url, @expiration_time_ms = @token_provider.generate_auth_token_from_credentials_provider(
      TestCredentialProvider.new
    )
    refute_nil @signed_url
    refute_nil @expiration_time_ms
  end
end
