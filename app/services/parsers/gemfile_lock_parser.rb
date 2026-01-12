module Parsers
  class GemfileLockParser < BaseParser
    def parse
      dependencies = []
      in_specs = false

      content.each_line do |line|
        # Look for the specs section
        if line.strip == "specs:"
          in_specs = true
          next
        end

        # Exit specs section when we hit a non-indented line
        if in_specs && !line.start_with?(" ")
          in_specs = false
          next
        end

        next unless in_specs

        # Parse gem specifications (4 spaces indent = top-level gem)
        if line.match?(/^    [a-zA-Z]/)
          match = line.match(/^\s{4}([a-zA-Z0-9_-]+)\s+\(([^)]+)\)/)
          if match
            name = match[1]
            version = match[2]
            dependencies << build_dependency(name: name, version: version)
          end
        end
      end

      dependencies
    end

    def ecosystem
      "rubygems"
    end

    private

    def purl_type
      "gem"
    end
  end
end
