# aws-msk-iam-sasl-signer

[![Gem Version](https://img.shields.io/gem/v/aws-msk-iam-sasl-signer)](https://rubygems.org/gems/aws-msk-iam-sasl-signer)
[![Gem Downloads](https://img.shields.io/gem/dt/aws-msk-iam-sasl-signer)](https://www.ruby-toolbox.com/projects/aws-msk-iam-sasl-signer)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby/ci.yml)](https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby/actions/workflows/ci.yml)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby)](https://codeclimate.com/github/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby)

This is an Amazon MSK Library in Ruby. 
This library provides a function to generates a base 64 encoded signed url to enable authentication/authorization with an MSK Cluster.
The signed url is generated by using your IAM credentials.

# Features

- Provides a function to generate auth token using IAM credentials from the AWS default credentials chain.
- Provides a function to generate auth token using IAM credentials from the AWS named profile.
- Provides a function to generate auth token using assumed IAM role’s credentials.

---

- [Quick start](#quick-start)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

# Get Started

## Installation

To install aws-msk-iam-sasl-signer-ruby, run this command in your terminal.
This is the preferred method to install aws-msk-iam-sasl-signer-ruby, as it will always install the most recent stable release.

```bash
gem install aws-msk-iam-sasl-signer
```

## Usage

```ruby

# frozen_string_literal: true
require "aws/msk/iam/sasl/signer"
require "json"
require "rdkafka"

KAFKA_TOPIC = ENV['KAFKA_TOPIC']
KAFKA_BOOTSTRAP_SERVERS = ENV['KAFKA_BOOTSTRAP_SERVERS']

kafka_config = {
  "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
  "security.protocol": 'sasl_ssl',
  "sasl.mechanisms": 'OAUTHBEARER',
  "client.id": 'ruby-producer',
}

def refresh_token(client, config)
  signer = Aws::Msk::Iam::Sasl::Signer::MSKTokenProvider.new(region: 'us-east-1')
  token, expiration_time_ms = signer.generate_auth_token

  error_buffer = FFI::MemoryPointer.from_string(' ' * 256)
  response = Rdkafka::Bindings.rd_kafka_oauthbearer_set_token(
    client, token, expiration_time_ms, 'kafka-cluster', nil, 0, error_buffer, 256
  )
  return unless response != 0

  Rdkafka::Bindings.rd_kafka_oauthbearer_set_token_failure(client,
                                                           "Failed to set token: #{error_buffer.read_string}")

end

# set the token refresh callback
Rdkafka::Config.oauthbearer_token_refresh_callback = method(:refresh_token)
producer = Rdkafka::Config.new(kafka_config).producer

# seed the token
# events_poll will invoke all registered callbacks, of which oauthbearer_token_refresh_callback is one

consumer = Rdkafka::Config.new(kafka_config).consumer
consumer.events_poll

# produce some messages

Payload = Data.define(:device_id, :creation_timestamp, :temperature)

loop do
  payload = Payload.new(
    device_id: '1234',
    creation_timestamp: Time.now.to_i,
    temperature: rand(0..100)
  )

  handle = producer.produce(
    topic: KAFKA_TOPIC,
    payload: payload.to_h.to_json,
    key: "ruby-kafka-#{rand(0..999)}"
  )
  handle.wait(max_wait_timeout: 10)

  sleep(10)
end

```

In order to use a named profile to generate the token, replace the `generate_auth_token` function with code below:

```ruby
  signer = Aws::Msk::Iam::Sasl::Signer::MSKTokenProvider.new(region: 'us-east-1')
  token, expiration_time_ms = signer.generate_auth_token_from_profile(
    aws_profile: 'my-profile'
  )
```


In order to use a role arn to generate the token, replace the `generate_auth_token` function with code below:

```ruby
    signer = Aws::Msk::Iam::Sasl::Signer::MSKTokenProvider.new(region: 'us-east-1')
    token, expiration_time_ms = signer.generate_auth_token_from_role_arn(
        role_arn: 'arn:aws:iam::1234567890:role/my-role'
    )
```

In order to use a custom credentials provider, replace the `generate_auth_token` function with code below :

```ruby
    signer = Aws::Msk::Iam::Sasl::Signer::MSKTokenProvider.new(region: 'us-east-1')
    token, expiration_time_ms = signer.generate_auth_token_from_credentials_provider(
      'your-credentials-provider'
    )
```

## Running tests

You can run tests in the currently configured Ruby version using `rake`.
By default, it will run all the unit tests.

```bash
bundle exec rake test
```

To fix lint issues, run `rubocop`.

```bash
bundle exec rubocop -x
```
## Code Climate 

This project uses [code climate](https://github.com/marketplace/code-climate) to maintain code quality.
Code Climate will be run on every pull request and will fail if the code quality is not maintained.
Code climate can be run locally using the commands below.

```bash
brew tap codeclimate/formulae
brew install codeclimate
bundle exec rake code_climate

## CLI

You can generate a signed url using the CLI.

```bash
bundle exec signer --help               
Commands:
  signer generate                                         # Generate a token using credential provider chain
  signer generate-from-profile --aws-profile=AWS_PROFILE  # Generate a token using aws profile
  signer generate-from-role-arn --role-arn=ROLE_ARN       # Generate a token using role arn
  signer help [COMMAND]                                   # Describe available commands or one specific command
```

## TroubleShooting

### Finding out which identity is being used

You may receive an Access denied error and there may be some doubt as to which credential is being exactly used.
The credential may be sourced from a role ARN, EC2 instance profile, credential profile etc.
When calling `generate_auth_token`, you can set `aws_debug` argument to `true`.

```ruby
MSKAuthTokenProvider.generate_auth_token(aws_debug: true)
```

The signer library will print a debug log of the form:

```ruby
Credentials Identity: {"user_id": "ABCD:test124", "account": "1234567890", "arn": "arn:aws:sts::1234567890:assumed-role/abc/test124"}
```

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
