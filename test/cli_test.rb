# frozen_string_literal: true

require "test_helper"
require "capture"
require "thor"

class AwsMskIamSaslSigner::CliTest < Minitest::Test
  def setup
    @auth_token = AwsMskIamSaslSigner::MSKTokenProvider::AuthToken.new(
      "token",
      Time.now.to_i,
      AwsMskIamSaslSigner::MSKTokenProvider::CallerIdentity.new("user_id", "account", "arn")
    )
  end

  def test_cli_with_no_commands
    c = Capture.capture do
      AwsMskIamSaslSigner::CLI.start
    end
    assert_match "Commands", c.stdout
  end

  def test_cli_version
    c = Capture.capture do
      AwsMskIamSaslSigner::CLI.start(["--version"])
    end
    assert_match "signer", c.stdout
  end

  def test_generate
    AwsMskIamSaslSigner::MSKTokenProvider.stub_any_instance :generate_auth_token, @auth_token do
      c = Capture.capture do
        AwsMskIamSaslSigner::CLI.start(["generate"])
      end
      assert_match "Token", c.stdout
      assert_match "Expiration Time", c.stdout
    end
  end

  def test_generate_with_debug
    AwsMskIamSaslSigner::MSKTokenProvider.stub_any_instance :generate_auth_token, @auth_token do
      c = Capture.capture do
        AwsMskIamSaslSigner::CLI.start(%w[generate --aws-debug])
      end
      assert_match "Caller Identity", c.stdout
    end
  end

  def test_generate_from_profile_no_profile
    assert_raises ::Thor::RequiredArgumentMissingError do
      AwsMskIamSaslSigner::CLI.start(["generate-from-profile"], exit_on_failure: false)
    end
  end

  def test_generate_from_profile_with_unknown_profile
    assert_raises Aws::Errors::NoSuchProfileError do
      AwsMskIamSaslSigner::CLI.start(%w[generate-from-profile --aws-profile foo], exit_on_failure: false)
    end
  end

  def test_generate_from_profile_with_known_profile
    AwsMskIamSaslSigner::MSKTokenProvider.stub_any_instance :generate_auth_token_from_profile, @auth_token do
      generate_token(%w[generate-from-profile --aws-profile known])
    end
  end

  def test_generate_from_role_arn_no_role
    assert_raises ::Thor::RequiredArgumentMissingError do
      AwsMskIamSaslSigner::CLI.start(["generate-from-role-arn"], exit_on_failure: false)
    end
  end

  def test_generate_from_role_arn_with_role_arn
    AwsMskIamSaslSigner::MSKTokenProvider.stub_any_instance :generate_auth_token_from_role_arn, @auth_token do
      generate_token(%w[generate-from-role-arn --role-arn known])
    end
  end

  private

  def generate_token(given_args)
    c = Capture.capture do
      AwsMskIamSaslSigner::CLI.start(given_args, exit_on_failure: false)
    end
    assert_match "Token", c.stdout
  end
end
