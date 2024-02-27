# frozen_string_literal: true

require "test_helper"
require "aws-sdk-kafka"
require "minitest/autorun"

class AwsMskIamSaslSigner::CredentialsResolverTest < Minitest::Test
  def test_from_credential_provider_chain_raises_error_when_no_credentials
    stub = Aws::Kafka::Client.new(stub_responses: true, credentials: nil)
    Aws::Kafka::Client.stub :new, stub do
      resolver = AwsMskIamSaslSigner::CredentialsResolver.new
      assert_raises(RuntimeError) { resolver.from_credential_provider_chain("us-east-1") }
    end
  end

  def test_from_credential_provider_chain_success
    stub = Aws::Kafka::Client.new(stub_responses: true)
    Aws::Kafka::Client.stub :new, stub do
      resolver = AwsMskIamSaslSigner::CredentialsResolver.new
      credentials = resolver.from_credential_provider_chain("us-east-1")
      assert_kind_of Aws::Credentials, credentials
    end
  end

  def test_from_profile
    creds = Aws::Credentials.new("access_key_id", "secret_access", "session_token")
    Aws::SharedCredentials.stub :new, creds do
      resolver = AwsMskIamSaslSigner::CredentialsResolver.new
      credentials = resolver.from_profile("test-profile")
      assert_kind_of Aws::Credentials, credentials
    end
  end

  def test_from_role_arn
    stub = Aws::STS::Client.new(stub_responses: true)
    Aws::STS::Client.stub :new, stub do
      resolver = AwsMskIamSaslSigner::CredentialsResolver.new
      credentials_provider = resolver.from_role_arn(
        role_arn: "arn:aws-msk-iam-sasl-signer:iam::123456789012:role/role-name",
        session_name: "test-session"
      )
      assert_respond_to credentials_provider, :credentials
    end
  end
end
