require "spec"
require "uri"
require "priority-queue"

# Minimal LSP stubs needed for TextDocument
module LSP
  module Initializer
    macro included
      {% verbatim do %}
      def self.new(**args)
        instance = self.allocate
        instance.initialize(args)
        instance
      end

      private def initialize(args : NamedTuple)
        {% for ivar in @type.instance_vars %}
          {% default_value = ivar.default_value %}
          {% if ivar.type.nilable? %}
            @{{ivar.id}} = args["{{ivar.id}}"]? {% if ivar.has_default_value? %}|| {{ default_value }}{% end %}
          {% else %}
            {% if ivar.has_default_value? %}
              @{{ivar.id}} = args["{{ivar.id}}"]? || {{ default_value }}
            {% else %}
              @{{ivar.id}} = args["{{ivar.id}}"]
            {% end %}
          {% end %}
        {% end %}
      end
      {% end %}
    end
  end

  class Position
    include Initializer
    property line : Int32 = 0
    property character : Int32 = 0
  end

  class Range
    include Initializer
    property start : Position = Position.new
    property end : Position = Position.new
  end
end

module Crystalline
  class Project
  end
end

require "../src/crystalline/text_document"

describe Crystalline::TextDocument do
  describe "#contents and #lines_nb" do
    it "stores and retrieves content" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello\nworld\n")
      doc.contents.should eq("hello\nworld\n")
    end

    it "counts lines correctly" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello\nworld\n")
      doc.lines_nb.should eq(2)
    end

    it "handles empty content" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "")
      doc.contents.should eq("")
      doc.lines_nb.should eq(0)
    end

    it "handles single line without newline" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello")
      doc.contents.should eq("hello")
      doc.lines_nb.should eq(1)
    end
  end

  describe "incremental updates" do
    it "inserts text in the middle of a line" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello world\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 5),
        end: LSP::Position.new(line: 0, character: 5),
      )
      doc.update_contents([{"X", range}])
      doc.contents.should eq("helloX world\n")
    end

    it "replaces text within a line" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello world\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 0),
        end: LSP::Position.new(line: 0, character: 5),
      )
      doc.update_contents([{"HELLO", range}])
      doc.contents.should eq("HELLO world\n")
    end

    it "deletes text within a line" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello world\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 5),
        end: LSP::Position.new(line: 0, character: 11),
      )
      doc.update_contents([{"", range}])
      doc.contents.should eq("hello\n")
    end

    it "inserts a new line" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello\nworld\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 5),
        end: LSP::Position.new(line: 0, character: 5),
      )
      doc.update_contents([{"\nnew line", range}])
      doc.contents.should eq("hello\nnew line\nworld\n")
    end

    it "replaces across multiple lines" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "line one\nline two\nline three\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 5),
        end: LSP::Position.new(line: 1, character: 5),
      )
      doc.update_contents([{"ONE\nLINE", range}])
      doc.contents.should eq("line ONE\nLINEtwo\nline three\n")
    end

    it "deletes an entire line" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "line one\nline two\nline three\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 1, character: 0),
        end: LSP::Position.new(line: 2, character: 0),
      )
      doc.update_contents([{"", range}])
      doc.contents.should eq("line one\nline three\n")
    end

    it "inserts at beginning of document" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "hello\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 0),
        end: LSP::Position.new(line: 0, character: 0),
      )
      doc.update_contents([{"prefix ", range}])
      doc.contents.should eq("prefix hello\n")
    end

    it "handles full update (nil range)" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "old content\n")

      doc.update_contents([{"new content\n", nil}])
      doc.contents.should eq("new content\n")
    end

    it "handles single character insertion" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "def foo\n  x = 1\nend\n")

      # Insert "0" after the "1" (at character 7, end of visible content)
      range = LSP::Range.new(
        start: LSP::Position.new(line: 1, character: 7),
        end: LSP::Position.new(line: 1, character: 7),
      )
      doc.update_contents([{"0", range}])
      doc.contents.should eq("def foo\n  x = 10\nend\n")
    end

    it "insert at end of visible content preserves newline" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "ab\ncd\n")

      range = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 2),
        end: LSP::Position.new(line: 0, character: 2),
      )
      doc.update_contents([{"X", range}])
      doc.contents.should eq("abX\ncd\n")
    end

    it "multiple sequential updates" do
      uri = URI.parse("file:///test.cr")
      doc = Crystalline::TextDocument.new(uri, nil, "abc\n")

      range1 = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 1),
        end: LSP::Position.new(line: 0, character: 1),
      )
      doc.update_contents([{"X", range1}])
      doc.contents.should eq("aXbc\n")

      range2 = LSP::Range.new(
        start: LSP::Position.new(line: 0, character: 3),
        end: LSP::Position.new(line: 0, character: 3),
      )
      doc.update_contents([{"Y", range2}])
      doc.contents.should eq("aXbYc\n")
    end
  end
end
