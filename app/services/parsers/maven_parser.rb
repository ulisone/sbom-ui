module Parsers
  class MavenParser < BaseParser
    def parse
      require "rexml/document"

      doc = REXML::Document.new(content)
      dependencies = []

      # Parse dependencies section
      doc.elements.each("project/dependencies/dependency") do |dep|
        group_id = dep.elements["groupId"]&.text
        artifact_id = dep.elements["artifactId"]&.text
        version = dep.elements["version"]&.text

        next unless group_id && artifact_id

        name = "#{group_id}:#{artifact_id}"
        version ||= "unknown"

        dependencies << build_dependency(
          name: name,
          version: version,
          purl: "pkg:maven/#{group_id}/#{artifact_id}@#{version}"
        )
      end

      # Parse dependency management section
      doc.elements.each("project/dependencyManagement/dependencies/dependency") do |dep|
        group_id = dep.elements["groupId"]&.text
        artifact_id = dep.elements["artifactId"]&.text
        version = dep.elements["version"]&.text

        next unless group_id && artifact_id && version

        name = "#{group_id}:#{artifact_id}"
        dependencies << build_dependency(
          name: name,
          version: version,
          purl: "pkg:maven/#{group_id}/#{artifact_id}@#{version}"
        )
      end

      dependencies.uniq { |d| d[:name] }
    rescue REXML::ParseException => e
      raise ParseError, "Invalid pom.xml: #{e.message}"
    end

    def ecosystem
      "maven"
    end

    private

    def purl_type
      "maven"
    end
  end
end
