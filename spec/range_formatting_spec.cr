require "spec"

# Tests for the range extraction logic used in range formatting.
# The original code used a fragile pattern where contents_lines[-1] and [0]
# alias the same element on single-line ranges. The fix makes the logic
# explicit and handles end_char=0 correctly for single-line ranges.

def extract_range(contents : String, start_line : Int32, start_char : Int32, end_line : Int32, end_char : Int32) : String
  contents_lines = contents.lines(chomp: false)[start_line..end_line]
  if start_line == end_line
    line = contents_lines[0]
    actual_end = end_char > 0 ? end_char : line.size
    contents_lines[0] = line[start_char...actual_end]
  else
    contents_lines[-1] = contents_lines.last[...end_char] if end_char > 0
    contents_lines[0] = contents_lines.first[start_char...]
  end
  contents_lines.join
end

describe "Range formatting extraction" do
  contents = "def foo\n  x = 1\n  y = 2\nend\n"

  describe "single-line range" do
    it "extracts a substring from a single line" do
      result = extract_range(contents, 1, 2, 1, 7)
      result.should eq("x = 1")
    end

    it "handles range at start of line" do
      result = extract_range(contents, 1, 0, 1, 5)
      result.should eq("  x =")
    end

    it "handles full line with end_char=0 (entire line)" do
      result = extract_range(contents, 1, 0, 1, 0)
      result.should eq("  x = 1\n")
    end

    it "extracts single character" do
      result = extract_range(contents, 0, 0, 0, 1)
      result.should eq("d")
    end
  end

  describe "multi-line range" do
    it "extracts multiple lines correctly" do
      result = extract_range(contents, 1, 0, 2, 7)
      result.should eq("  x = 1\n  y = 2")
    end

    it "extracts with start offset" do
      result = extract_range(contents, 1, 2, 2, 7)
      result.should eq("x = 1\n  y = 2")
    end

    it "handles end_char=0 for multi-line (full last line)" do
      result = extract_range(contents, 0, 0, 1, 0)
      result.should eq("def foo\n  x = 1\n")
    end
  end

  describe "edge cases" do
    it "handles entire document" do
      result = extract_range(contents, 0, 0, 3, 0)
      result.should eq(contents)
    end

    it "handles empty result from single-line with same start and end char" do
      result = extract_range(contents, 0, 3, 0, 3)
      result.should eq("")
    end
  end
end
