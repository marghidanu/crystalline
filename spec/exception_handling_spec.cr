require "spec"

# Tests validating the exception handling pattern used across the codebase.
# The fix replaces bare `rescue` / `rescue; nil` with `rescue e; log; nil`
# so that errors are captured and logged instead of silently swallowed.

describe "Exception handling pattern" do
  it "bare rescue swallows exception silently" do
    result = begin
      raise "test error"
    rescue
      nil
    end
    result.should be_nil
    # No way to know what happened - bad pattern
  end

  it "named rescue captures exception for logging" do
    captured_message = nil
    result = begin
      raise "test error"
    rescue e
      captured_message = e.message
      nil
    end
    result.should be_nil
    captured_message.should eq("test error")
  end

  it "preserves exception type information" do
    captured_class = nil
    begin
      raise ArgumentError.new("bad arg")
    rescue e
      captured_class = e.class.name
    end
    captured_class.should eq("ArgumentError")
  end

  it "can log exception with context prefix" do
    log_output = nil
    begin
      raise "something broke"
    rescue e
      log_output = "method_name: #{e.message}"
    end
    log_output.should eq("method_name: something broke")
  end

  it "handles nil exception message gracefully" do
    begin
      raise Exception.new(nil)
    rescue e
      msg = e.message || "Unknown error"
      msg.should eq("Unknown error")
    end
  end
end
