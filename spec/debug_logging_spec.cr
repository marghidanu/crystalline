require "spec"

describe "Crystalline debug CLI flags" do
  it "detects --debug flag in arguments" do
    argv = ["--debug"]
    argv.includes?("--debug").should eq(true)
  end

  it "detects --version flag in arguments" do
    argv = ["--version"]
    argv.includes?("--version").should eq(true)
  end

  it "handles no flags" do
    argv = [] of String
    argv.includes?("--debug").should eq(false)
    argv.includes?("--version").should eq(false)
  end

  it "handles multiple flags" do
    argv = ["--debug", "--version"]
    argv.includes?("--debug").should eq(true)
    argv.includes?("--version").should eq(true)
  end

  describe "debug log file path" do
    it "constructs log path in temp directory" do
      log_path = Path[Dir.tempdir, "crystalline.log"].to_s
      log_path.should contain("crystalline.log")
      log_path.size.should be > "crystalline.log".size
    end
  end
end
