# frozen_string_literal: true
require "test_helper"
require "aws-sdk-kafka"
require "minitest/autorun"

class Aws::Msk::Iam::Sasl::CredentialResolverTest < Minitest::Test

  def test_from_credential_provider_chain_raises_error_when_no_credentials
    stub = Aws::Kafka::Client.new(stub_responses: true, credentials: nil)
    Aws::Kafka::Client.stub :new, stub do
      resolver = Aws::Msk::Iam::Sasl::Signer::CredentialResolver.new
      assert_raises(RuntimeError) { resolver.from_credential_provider_chain("us-east-1") }
    end
  end

  def test_from_credential_provider_chain_success
    stub = Aws::Kafka::Client.new(stub_responses: true)
    Aws::Kafka::Client.stub :new, stub do
      resolver = Aws::Msk::Iam::Sasl::Signer::CredentialResolver.new
      credentials = resolver.from_credential_provider_chain("us-east-1")
      assert_kind_of Aws::Credentials, credentials
    end
  end
  
  def test_from_profile
    creds = Aws::Credentials.new("access_key_id", "secret_access", "session_token")
    Aws::SharedCredentials.stub :new, creds do
      resolver = Aws::Msk::Iam::Sasl::Signer::CredentialResolver.new
      credentials = resolver.from_profile("test-profile")
      assert_kind_of Aws::Credentials, credentials
    end
  end

  def test_from_role_arn
    stub = Aws::STS::Client.new(stub_responses: true)
    Aws::STS::Client.stub :new, stub do
      resolver = Aws::Msk::Iam::Sasl::Signer::CredentialResolver.new
      credentials = resolver.from_role_arn(role_arn: "arn:aws:iam::123456789012:role/role-name", session_name: "test-session")
      assert_kind_of Aws::STS::Types::Credentials, credentials
    end
  end
end