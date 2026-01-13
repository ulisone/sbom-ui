# SBOM Engine API Configuration
Rails.application.configure do
  config.sbom_engine = {
    base_url: ENV.fetch("SBOM_ENGINE_URL", "http://localhost:5699"),
    timeout: ENV.fetch("SBOM_ENGINE_TIMEOUT", 30).to_i,
    enabled: ENV.fetch("SBOM_ENGINE_ENABLED", "true") == "true"
  }
end
