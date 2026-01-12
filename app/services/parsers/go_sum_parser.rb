module Parsers
  class GoSumParser < BaseParser
    def parse
      dependencies = []
      seen = Set.new

      content.each_line do |line|
        line = line.strip
        next if line.empty?

        # Format: module/path v1.2.3 h1:hash
        # or: module/path v1.2.3/go.mod h1:hash
        parts = line.split(/\s+/)
        next if parts.length < 2

        name = parts[0]
        version = parts[1].gsub(%r{/go\.mod$}, "")

        # Deduplicate
        key = "#{name}@#{version}"
        next if seen.include?(key)
        seen.add(key)

        dependencies << build_dependency(
          name: name,
          version: version,
          purl: "pkg:golang/#{name}@#{version}"
        )
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
  end
end
