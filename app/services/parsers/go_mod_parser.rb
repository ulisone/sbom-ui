module Parsers
  class GoModParser < BaseParser
    def parse
      dependencies = []
      in_require_block = false

      content.each_line do |line|
        line = line.strip

        # Handle require block
        if line.start_with?("require (")
          in_require_block = true
          next
        end

        if in_require_block
          if line == ")"
            in_require_block = false
            next
          end

          dep = parse_require_line(line)
          dependencies << dep if dep
          next
        end

        # Handle single line require
        if line.start_with?("require ")
          dep = parse_require_line(line.sub(/^require\s+/, ""))
          dependencies << dep if dep
        end
      end

      dependencies
    end

    def ecosystem
      "go"
    end

    private

    def purl_type
      "golang"
    end

    def parse_require_line(line)
      # Skip comments
      line = line.split("//").first.strip
      return nil if line.empty?

      # Parse: module/path v1.2.3
      parts = line.split(/\s+/)
      return nil if parts.length < 2

      name = parts[0]
      version = parts[1]

      # Skip indirect dependencies marker
      version = version.gsub(/\s*\/\/.*$/, "")

      build_dependency(
        name: name,
        version: version,
        purl: "pkg:golang/#{name}@#{version}"
      )
    end
  end
end
