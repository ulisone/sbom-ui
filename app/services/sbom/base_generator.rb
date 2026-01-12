module Sbom
  class BaseGenerator
    attr_reader :dependencies, :metadata

    def initialize(dependencies, metadata = {})
      @dependencies = dependencies
      @metadata = metadata
    end

    def generate
      raise NotImplementedError, "Subclasses must implement #generate"
    end

    def format
      raise NotImplementedError, "Subclasses must implement #format"
    end

    def to_json
      JSON.pretty_generate(generate)
    end

    protected

    def timestamp
      Time.current.utc.iso8601
    end

    def uuid
      SecureRandom.uuid
    end
  end
end
