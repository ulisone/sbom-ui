module Parsers
  class NpmLockParser < BaseParser
    def parse
      data = JSON.parse(content)
      dependencies = []

      # npm v2+ lockfile format (packages)
      if data["packages"]
        data["packages"].each do |path, info|
          next if path.empty? # Skip root package
          next unless info["version"]

          name = extract_package_name(path)
          dependencies << build_dependency(
            name: name,
            version: info["version"],
            license: info["license"]
          )
        end
      # npm v1 lockfile format (dependencies)
      elsif data["dependencies"]
        parse_dependencies_v1(data["dependencies"], dependencies)
      end

      dependencies.uniq { |d| [d[:name], d[:version]] }
    rescue JSON::ParserError => e
      raise ParseError, "Invalid package-lock.json: #{e.message}"
    end

    def ecosystem
      "npm"
    end

    private

    def purl_type
      "npm"
    end

    def extract_package_name(path)
      # path format: node_modules/@scope/package or node_modules/package
      path.gsub(%r{^node_modules/}, "").gsub(%r{/node_modules/.*}, "")
    end

    def parse_dependencies_v1(deps, result)
      deps.each do |name, info|
        if info["version"]
          result << build_dependency(name: name, version: info["version"])
        end

        # Parse nested dependencies
        if info["dependencies"]
          parse_dependencies_v1(info["dependencies"], result)
        end
      end
    end
  end
end
