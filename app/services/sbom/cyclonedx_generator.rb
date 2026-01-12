module Sbom
  class CyclonedxGenerator < BaseGenerator
    SPEC_VERSION = "1.5"
    SCHEMA_URL = "http://cyclonedx.org/schema/bom-1.5.schema.json"

    def format
      "cyclonedx"
    end

    def generate
      {
        "$schema" => SCHEMA_URL,
        "bomFormat" => "CycloneDX",
        "specVersion" => SPEC_VERSION,
        "serialNumber" => "urn:uuid:#{uuid}",
        "version" => 1,
        "metadata" => generate_metadata,
        "components" => generate_components
      }
    end

    private

    def generate_metadata
      meta = {
        "timestamp" => timestamp,
        "tools" => {
          "components" => [
            {
              "type" => "application",
              "name" => "SBOM Dashboard",
              "version" => "1.0.0"
            }
          ]
        }
      }

      if metadata[:component_name]
        meta["component"] = {
          "type" => "application",
          "name" => metadata[:component_name],
          "version" => metadata[:component_version] || "0.0.0"
        }
      end

      meta
    end

    def generate_components
      dependencies.map do |dep|
        component = {
          "type" => "library",
          "name" => dep[:name],
          "version" => dep[:version] || "unknown",
          "purl" => dep[:purl]
        }

        component["bom-ref"] = dep[:purl] if dep[:purl]

        if dep[:license]
          component["licenses"] = [
            {
              "license" => {
                "id" => dep[:license]
              }
            }
          ]
        end

        if dep[:ecosystem]
          component["properties"] = [
            {
              "name" => "ecosystem",
              "value" => dep[:ecosystem]
            }
          ]
        end

        component
      end
    end
  end
end
