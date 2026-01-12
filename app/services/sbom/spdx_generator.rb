module Sbom
  class SpdxGenerator < BaseGenerator
    SPDX_VERSION = "SPDX-2.3"
    DATA_LICENSE = "CC0-1.0"

    def format
      "spdx"
    end

    def generate
      {
        "spdxVersion" => SPDX_VERSION,
        "dataLicense" => DATA_LICENSE,
        "SPDXID" => "SPDXRef-DOCUMENT",
        "name" => metadata[:document_name] || "SBOM Document",
        "documentNamespace" => generate_namespace,
        "creationInfo" => generate_creation_info,
        "packages" => generate_packages,
        "relationships" => generate_relationships
      }
    end

    private

    def generate_namespace
      base_name = metadata[:document_name]&.gsub(/\s+/, "-") || "sbom"
      "https://spdx.org/spdxdocs/#{base_name}-#{uuid}"
    end

    def generate_creation_info
      {
        "created" => timestamp,
        "creators" => [
          "Tool: SBOM Dashboard-1.0.0"
        ],
        "licenseListVersion" => "3.21"
      }
    end

    def generate_packages
      packages = []

      # Root package (the project itself)
      if metadata[:component_name]
        packages << {
          "SPDXID" => "SPDXRef-Package-root",
          "name" => metadata[:component_name],
          "versionInfo" => metadata[:component_version] || "0.0.0",
          "downloadLocation" => "NOASSERTION",
          "filesAnalyzed" => false,
          "licenseConcluded" => "NOASSERTION",
          "licenseDeclared" => "NOASSERTION",
          "copyrightText" => "NOASSERTION"
        }
      end

      # Dependencies as packages
      dependencies.each_with_index do |dep, index|
        packages << {
          "SPDXID" => spdx_id(dep, index),
          "name" => dep[:name],
          "versionInfo" => dep[:version] || "unknown",
          "downloadLocation" => "NOASSERTION",
          "filesAnalyzed" => false,
          "licenseConcluded" => dep[:license] || "NOASSERTION",
          "licenseDeclared" => dep[:license] || "NOASSERTION",
          "copyrightText" => "NOASSERTION",
          "externalRefs" => generate_external_refs(dep)
        }.compact
      end

      packages
    end

    def generate_relationships
      relationships = [
        {
          "spdxElementId" => "SPDXRef-DOCUMENT",
          "relatedSpdxElement" => "SPDXRef-Package-root",
          "relationshipType" => "DESCRIBES"
        }
      ]

      dependencies.each_with_index do |dep, index|
        relationships << {
          "spdxElementId" => "SPDXRef-Package-root",
          "relatedSpdxElement" => spdx_id(dep, index),
          "relationshipType" => "DEPENDS_ON"
        }
      end

      relationships
    end

    def generate_external_refs(dep)
      return nil unless dep[:purl]

      [
        {
          "referenceCategory" => "PACKAGE-MANAGER",
          "referenceType" => "purl",
          "referenceLocator" => dep[:purl]
        }
      ]
    end

    def spdx_id(dep, index)
      # Create valid SPDX ID from package name
      safe_name = dep[:name].gsub(/[^a-zA-Z0-9.-]/, "-")
      "SPDXRef-Package-#{safe_name}-#{index}"
    end
  end
end
