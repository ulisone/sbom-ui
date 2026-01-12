module Parsers
  class NpmParser < BaseParser
    def parse
      data = JSON.parse(content)
      dependencies = []

      # Parse regular dependencies
      (data["dependencies"] || {}).each do |name, version|
        version_str = normalize_version(version)
        dependencies << build_dependency(name: name, version: version_str)
      end

      # Parse dev dependencies
      (data["devDependencies"] || {}).each do |name, version|
        version_str = normalize_version(version)
        dependencies << build_dependency(name: name, version: version_str)
      end

      dependencies
    rescue JSON::ParserError => e
      raise ParseError, "Invalid package.json: #{e.message}"
    end

    def ecosystem
      "npm"
    end

    private

    def purl_type
      "npm"
    end

    def normalize_version(version)
      # Remove semver prefixes like ^, ~, >=, etc.
      version.to_s.gsub(/^[\^~>=<]+/, "").strip
    end
  end
end
