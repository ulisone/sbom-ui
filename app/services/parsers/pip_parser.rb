module Parsers
  class PipParser < BaseParser
    def parse
      dependencies = []

      content.each_line do |line|
        line = line.strip

        # Skip comments and empty lines
        next if line.empty? || line.start_with?("#")

        # Skip options like -r, --index-url, etc.
        next if line.start_with?("-")

        # Parse package specification
        dep = parse_requirement(line)
        dependencies << dep if dep
      end

      dependencies
    end

    def ecosystem
      "pypi"
    end

    private

    def purl_type
      "pypi"
    end

    def parse_requirement(line)
      # Handle different formats:
      # package==1.0.0
      # package>=1.0.0
      # package~=1.0.0
      # package[extra]==1.0.0
      # package @ https://...

      # Remove inline comments
      line = line.split("#").first.strip

      # Skip URL-based requirements
      return nil if line.include?(" @ ")

      # Match package name and version
      match = line.match(/^([a-zA-Z0-9_-]+)(?:\[.*?\])?(?:([<>=!~]+)(.+))?$/)
      return nil unless match

      name = match[1]
      version = match[3]&.strip&.split(",")&.first || "unknown"

      build_dependency(name: name, version: version)
    end
  end
end
