# frozen_string_literal: true

require "stringio"

class Capture
  Captured = Data.define(:result, :stdout, :stderr)

  def self.capture
    # redirect output to StringIO objects
    stdout = StringIO.new
    stderr = StringIO.new
    $stdout = stdout
    $stderr = stderr

    result = yield

    # restore normal output
    $stdout = STDOUT
    $stderr = STDERR

    Captured.new(result: result, stdout: stdout.string, stderr: stderr.string)
  end
end
