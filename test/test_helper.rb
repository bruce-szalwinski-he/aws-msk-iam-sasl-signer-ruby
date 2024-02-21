$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "aws/msk/iam/sasl/signer"

require "minitest/autorun"
require "minitest/stub_any_instance"
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |rb| require(rb) }

def assert_gt(a, b)
  assert_operator a, :>, b
end

def assert_gte(a, b)
  assert_operator a, :>=, b
end

def assert_lt(a, b)
  assert_operator a, :<, b
end

def assert_lte(a, b)
  assert_operator a, :<=, b
end
