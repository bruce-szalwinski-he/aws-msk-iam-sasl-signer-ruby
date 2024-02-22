require "aws-sdk-kafka"
require "aws-sigv4"
require "base64"
require "uri"

module Aws::Msk::Iam::Sasl::Signer
  autoload :MSKTokenProvider, "aws/msk/iam/sasl/signer/msk_token_provider"
  autoload :CredentialResolver, "aws/msk/iam/sasl/signer/credential_resolver"
  autoload :VERSION, "aws/msk/iam/sasl/signer/version"
  autoload :CLI, "aws/msk/iam/sasl/signer/cli"
  autoload :ThorExt, "aws/msk/iam/sasl/signer/thor_ext"
end
