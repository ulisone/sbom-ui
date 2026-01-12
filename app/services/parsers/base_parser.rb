module Parsers
  class BaseParser
    attr_reader :content, :file_name

    def initialize(content, file_name = nil)
      @content = content
      @file_name = file_name
    end

    def parse
      raise NotImplementedError, "Subclasses must implement #parse"
    end

    def ecosystem
      raise NotImplementedError, "Subclasses must implement #ecosystem"
    end

    def self.for(file_name, content)
      parser_class = case file_name.downcase
      when "package.json"
        Parsers::NpmParser
      when "package-lock.json"
        Parsers::NpmLockParser
      when "requirements.txt", "requirements-dev.txt"
        Parsers::PipParser
      when "pipfile.lock"
        Parsers::PipfileLockParser
      when "gemfile.lock"
        Parsers::GemfileLockParser
      when "pom.xml"
        Parsers::MavenParser
      when "go.mod"
        Parsers::GoModParser
      when "go.sum"
        Parsers::GoSumParser
      when "cargo.lock"
        Parsers::CargoParser
      else
        raise UnsupportedFileError, "Unsupported file type: #{file_name}"
      end

      parser_class.new(content, file_name)
    end

    protected

    def build_dependency(name:, version:, purl: nil, license: nil)
      {
        name: name,
        version: version,
        ecosystem: ecosystem,
        purl: purl || build_purl(name, version),
        license: license
      }
    end

    def build_purl(name, version)
      "pkg:#{purl_type}/#{name}@#{version}"
    end

    def purl_type
      raise NotImplementedError, "Subclasses must implement #purl_type"
    end

    class UnsupportedFileError < StandardError; end
    class ParseError < StandardError; end
  end
end
