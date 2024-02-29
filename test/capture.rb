# frozen_string_literal: true

require "stringio"

class Capture
  CAPTURED = if defined?(Data)
               Data.define(:result, :stdout, :stderr)
             else
               Struct.new(:result, :stdout, :stderr)
             end

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

    CAPTURED.new(result, stdout.string, stderr.string)
  end
end
