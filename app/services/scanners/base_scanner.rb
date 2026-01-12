module Scanners
  class BaseScanner
    attr_reader :sbom_content, :sbom_format

    def initialize(sbom_content, sbom_format)
      @sbom_content = sbom_content
      @sbom_format = sbom_format
    end

    def scan
      raise NotImplementedError, "Subclasses must implement #scan"
    end

    def self.for(scanner_type)
      case scanner_type.to_s.downcase
      when "trivy"
        Scanners::TrivyScanner
      else
        raise UnsupportedScannerError, "Unsupported scanner: #{scanner_type}"
      end
    end

    class ScanError < StandardError; end
    class UnsupportedScannerError < StandardError; end
  end
end
