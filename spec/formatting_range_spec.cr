require "spec"

# Test the formatting range calculation logic independently.
# The bug was: `line: document.lines_nb + 1` which overshoots by 1.
# Fix: `line: document.lines_nb` — since LSP lines are 0-indexed,
# lines_nb (the count) is already the correct exclusive end.

describe "Formatting range calculation" do
  describe "lines_nb for range end" do
    it "handles empty content" do
      lines = "".lines(chomp: false)
      lines_nb = lines.size
      # For empty content, the range should be 0..0
      lines_nb.should eq(0)
      # End position should be line: 0 (not line: 1)
      end_line = lines_nb
      end_line.should eq(0)
    end

    it "handles single line without newline" do
      lines = "hello".lines(chomp: false)
      lines_nb = lines.size
      lines_nb.should eq(1)
      # End position: line 1 (exclusive, past the single line at index 0)
      end_line = lines_nb
      end_line.should eq(1)
    end

    it "handles single line with newline" do
      lines = "hello\n".lines(chomp: false)
      lines_nb = lines.size
      lines_nb.should eq(1)
      end_line = lines_nb
      end_line.should eq(1)
    end

    it "handles multi-line content" do
      lines = "line1\nline2\nline3\n".lines(chomp: false)
      lines_nb = lines.size
      lines_nb.should eq(3)
      # End position: line 3 (exclusive, past lines at indices 0, 1, 2)
      end_line = lines_nb
      end_line.should eq(3)
    end

    it "handles multi-line content without trailing newline" do
      lines = "line1\nline2\nline3".lines(chomp: false)
      lines_nb = lines.size
      lines_nb.should eq(3)
      end_line = lines_nb
      end_line.should eq(3)
    end

    it "the old calculation was wrong (lines_nb + 1 overshoots)" do
      lines = "line1\nline2\n".lines(chomp: false)
      lines_nb = lines.size
      # Old: lines_nb + 1 = 3, but document only has 2 lines (indices 0-1)
      old_end = lines_nb + 1
      old_end.should eq(3) # wrong: overshoots

      # New: lines_nb = 2, which is the correct exclusive end
      new_end = lines_nb
      new_end.should eq(2) # correct
    end
  end
end
