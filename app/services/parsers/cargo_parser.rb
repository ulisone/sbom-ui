module Parsers
  class CargoParser < BaseParser
    def parse
      dependencies = []
      current_package = nil

      content.each_line do |line|
        line = line.strip

        # New package section
        if line == "[[package]]"
          current_package = {}
          next
        end

        next unless current_package

        # Parse package attributes
        if line.start_with?('name = "')
          current_package[:name] = line.match(/name = "(.+)"/)&.[](1)
        elsif line.start_with?('version = "')
          current_package[:version] = line.match(/version = "(.+)"/)&.[](1)
        end

        # When we have both name and version, add the dependency
        if current_package[:name] && current_package[:version]
          dependencies << build_dependency(
            name: current_package[:name],
            version: current_package[:version]
          )
          current_package = nil
        end
      end

      dependencies
    end

    def ecosystem
      "cargo"
    end

    private

    def purl_type
      "cargo"
    end
  end
end
