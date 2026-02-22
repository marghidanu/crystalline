require "log"
require "lsp/server"
require "./ext/*"
require "./*"

module Crystalline
  VERSION = {{ (`shards version #{__DIR__}`.strip + "+" +
                system("git rev-parse --short HEAD || echo unknown").stringify).stringify.strip }}
  # Supported server capabilities.
  SERVER_CAPABILITIES = LSP::ServerCapabilities.new(
    text_document_sync: LSP::TextDocumentSyncKind::Incremental,
    document_formatting_provider: true,
    document_range_formatting_provider: true,
    completion_provider: LSP::CompletionOptions.new(
      trigger_characters: [".", ":", "@"],
    ),
    hover_provider: true,
    definition_provider: true,
    document_symbol_provider: true,
    # signature_help_provider: LSP::SignatureHelpOptions.new(
    #   trigger_characters: ["(", " "]
    # ),
  )

  module EnvironmentConfig
    # Add the `crystal env` environment variables to the current env.
    def self.run
      initialize_from_crystal_env.each do |k, v|
        ENV[k] = v
      end
    end

    private def self.initialize_from_crystal_env
      crystal_env
        .lines
        .map(&.split('='))
        .to_h
    end

    private def self.crystal_env
      String.build do |io|
        Process.run("crystal", ["env"], output: io)
      end
    end
  end

  class_property? debug : Bool = false

  def self.init(*, input : IO = STDIN, output : IO = STDOUT, debug : Bool = false)
    EnvironmentConfig.run
    self.debug = debug
    if debug
      log_file = File.open(Path[Dir.tempdir, "crystalline.log"].to_s, "a")
      log_file.sync = true
      backend = ::Log::IOBackend.new(io: log_file)
      ::Log.setup(:debug, backend)
      LSP::Log.info { "Crystalline v#{VERSION} started in debug mode" }
    end
    server = LSP::Server.new(input, output, SERVER_CAPABILITIES)
    Controller.new(server)
  rescue ex
    LSP::Log.error(exception: ex) { %(#{ex.message || "Unknown error during init."}\n#{ex.backtrace.join('\n')}) }
  end
end
