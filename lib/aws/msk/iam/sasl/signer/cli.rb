# frozen_string_literal: true

require "thor"

module Aws::Msk::Iam::Sasl::Signer
  class CLI < Thor
    extend ThorExt::Start
    map %w[-v --version] => "version"
    desc "version", "Display signer version", hide: true
    def version
      say "signer/#{VERSION} #{RUBY_DESCRIPTION}"
    end

    desc "generate", "Generate a token using credential provider chain"
    option :region, type: :string, default: "us-east-1", desc: "The AWS region"
    option :aws_debug, type: :boolean, default: false, desc: "Log caller identity when using credential provider chain"
    def generate
      token_provider = MSKTokenProvider.new(region: options[:region])
      signed_url, expiration_time_ms = token_provider.generate_auth_token(aws_debug: options[:aws_debug])

      puts "Token: #{signed_url}"
      puts "Expiration Time: #{expiration_time_ms}"
    end

    desc "generate-from-profile", "Generate a token using aws profile"
    option :region, type: :string, default: "us-east-1", desc: "The AWS region"
    option :aws_profile, type: :string, desc: "Name of the AWS profile"
    def generate_from_profile
      token_provider = MSKTokenProvider.new(region: options[:region])

      signed_url, expiration_time_ms = token_provider.generate_auth_token_from_profile(options[:aws_profile])
      puts "Token: #{signed_url}"
      puts "Expiration Time: #{expiration_time_ms}"
    end

    desc "generate-from-role-arn", "Generate a token using role arn"
    option :region, type: :string, default: "us-east-1", desc: "The AWS region"
    option :role_arn, type: :string, desc: "ARN of the role to assume"
    option :session_name, type: :string, default: nil, desc: "The session name to use when assuming a role"
    def generate_from_role_arn
      token_provider = MSKTokenProvider.new(region: options[:region])
      signed_url, expiration_time_ms = token_provider.generate_auth_token_from_role_arn(
        options[:role_arn],
        options[:session_name]
      )

      puts "Token: #{signed_url}"
      puts "Expiration Time: #{expiration_time_ms}"
    end
  end
end
