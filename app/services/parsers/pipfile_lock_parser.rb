module Parsers
  class PipfileLockParser < BaseParser
    def parse
      data = JSON.parse(content)
      dependencies = []

      # Parse default packages
      (data["default"] || {}).each do |name, info|
        version = info["version"]&.gsub(/^==/, "")
        next unless version

        dependencies << build_dependency(name: name, version: version)
      end

      # Parse develop packages
      (data["develop"] || {}).each do |name, info|
        version = info["version"]&.gsub(/^==/, "")
        next unless version

        dependencies << build_dependency(name: name, version: version)
      end

      dependencies
    rescue JSON::ParserError => e
      raise ParseError, "Invalid Pipfile.lock: #{e.message}"
    end

    def ecosystem
      "pypi"
    end

    private

    def purl_type
      "pypi"
    end
  end
end
