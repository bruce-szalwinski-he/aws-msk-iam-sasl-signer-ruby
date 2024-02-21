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

    desc "generate", "Generate a token"
    option :region, type: :string, default: "us-east-1", desc: "The AWS region"
    def generate
      token_provider = MSKTokenProvider.new(region: options[:region])
      signed_url, expiration_time_ms = token_provider.generate_auth_token
      puts "Token: #{signed_url}"
      puts "Expiration Time: #{expiration_time_ms}"
    end
  end
end
