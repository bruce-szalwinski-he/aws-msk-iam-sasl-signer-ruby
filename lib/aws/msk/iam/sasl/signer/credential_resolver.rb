# frozen_string_literal: true

module Aws::Msk::Iam::Sasl::Signer
  class CredentialResolver
    def from_credential_provider_chain(region)
       client = Aws::Kafka::Client.new(region: region)
      raise "No credentials found" unless client.config.credentials

      client.config.credentials.credentials
    end

    def from_profile(profile)
      credentials = Aws::SharedCredentials.new(profile_name: profile)
      credentials.credentials
    end

    def from_role_arn(role_arn:, session_name:)
      sts = Aws::STS::Client.new
      assumed_role = sts.assume_role({ role_arn: role_arn, role_session_name: session_name })
      assumed_role.credentials
    end
  end
end
