require_relative "lib/aws/msk/iam/sasl/signer/version"

Gem::Specification.new do |spec|
  spec.name = "aws-msk-iam-sasl-signer"
  spec.version = Aws::Msk::Iam::Sasl::Signer::VERSION
  spec.authors = ["bruce szalwinski"]
  spec.email = ["bruce.szalwinski@hotelengine.com"]

  spec.summary = "MSK Library in Ruby for SASL/OAUTHBEARER Auth"
  spec.homepage = "https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby/issues",
    "changelog_uri" => "https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby/releases",
    "source_code_uri" => "https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[LICENSE.txt README.md {exe,lib}/**/*]).reject { |f| File.directory?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "aws-sdk-kafka", "~> 1.68"
  spec.add_dependency "thor", "~> 1.3"
end
