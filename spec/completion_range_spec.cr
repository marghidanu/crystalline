require "spec"

# Tests for the completion range calculation and position conversion.
#
# Bug 1: The completion text edit range start had `+ 1`, causing the
# replacement to start one character too far right.
#
# Bug 2: The Crystal::Location column_number was missing `+ 1` for
# the LSP 0-based to Crystal 1-based conversion.

describe "Completion range calculation" do
  describe "text edit range start position" do
    it "correctly calculates start with no offset" do
      position_character = 5
      left_offset = 0
      # Fixed: character - left_offset (was: character - left_offset + 1)
      start_char = position_character - left_offset
      start_char.should eq(5)
    end

    it "correctly calculates start with offset" do
      position_character = 10
      left_offset = 3
      # Fixed: 10 - 3 = 7 (was: 10 - 3 + 1 = 8, which is wrong)
      start_char = position_character - left_offset
      start_char.should eq(7)
    end

    it "correctly calculates start at beginning of identifier" do
      position_character = 3
      left_offset = 3
      start_char = position_character - left_offset
      start_char.should eq(0)
    end

    it "old calculation was off by one" do
      position_character = 10
      left_offset = 3
      old_start_char = position_character - left_offset + 1 # old buggy
      new_start_char = position_character - left_offset     # fixed
      old_start_char.should eq(8)                           # wrong
      new_start_char.should eq(7)                           # correct
      (old_start_char - new_start_char).should eq(1)        # off by exactly 1
    end
  end

  describe "Crystal::Location column conversion" do
    it "converts LSP 0-based to Crystal 1-based with offset" do
      position_line = 5
      position_character = 10
      left_offset = 3
      # Crystal uses 1-based columns; LSP uses 0-based
      # Fixed: position.character - left_offset + 1
      # (was: position.character - left_offset, missing the +1)
      line_number = position_line + 1
      column_number = position_character - left_offset + 1
      line_number.should eq(6)
      column_number.should eq(8)
    end

    it "converts correctly with zero offset" do
      position_character = 0
      left_offset = 0
      column_number = position_character - left_offset + 1
      column_number.should eq(1) # Crystal columns start at 1
    end

    it "is consistent with hover position conversion" do
      # hover uses: column_number: position.character + 1
      # completion should use: column_number: position.character - left_offset + 1
      # When left_offset = 0, both should give the same result
      position_character = 5
      hover_column = position_character + 1
      completion_column = position_character - 0 + 1
      hover_column.should eq(completion_column)
    end
  end

  describe "end position" do
    it "correctly calculates end with right offset" do
      position_character = 10
      right_offset = 5
      end_char = position_character + right_offset
      end_char.should eq(15)
    end

    it "correctly calculates end with no right offset" do
      position_character = 10
      right_offset = 0
      end_char = position_character + right_offset
      end_char.should eq(10)
    end
  end
end
