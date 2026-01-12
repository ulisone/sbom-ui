class GitRepositoryService
  DEPENDENCY_FILES = %w[
    package.json
    package-lock.json
    yarn.lock
    requirements.txt
    Pipfile
    Pipfile.lock
    Gemfile
    Gemfile.lock
    pom.xml
    build.gradle
    go.mod
    go.sum
    Cargo.toml
    Cargo.lock
    composer.json
    composer.lock
  ].freeze

  class GitError < StandardError; end

  attr_reader :repository_url, :clone_path

  def initialize(repository_url)
    @repository_url = sanitize_url(repository_url)
    @clone_path = Rails.root.join("tmp", "repos", SecureRandom.hex(8))
  end

  def clone_and_scan
    clone_repository
    find_dependency_files
  ensure
    cleanup
  end

  def find_dependency_files
    return [] unless Dir.exist?(clone_path)

    files = []
    DEPENDENCY_FILES.each do |filename|
      # Search for files in root and common subdirectories
      patterns = [
        File.join(clone_path, filename),
        File.join(clone_path, "**", filename)
      ]

      patterns.each do |pattern|
        Dir.glob(pattern).each do |path|
          next if path.include?("node_modules")
          next if path.include?("vendor")
          next if path.include?(".git")

          files << {
            name: File.basename(path),
            path: path,
            relative_path: path.sub("#{clone_path}/", ""),
            content: File.read(path)
          }
        end
      end
    end

    files.uniq { |f| f[:relative_path] }
  end

  private

  def sanitize_url(url)
    # Convert SSH URLs to HTTPS
    url = url.strip
    url = url.gsub(/^git@github\.com:/, "https://github.com/")
    url = url.gsub(/^git@gitlab\.com:/, "https://gitlab.com/")
    url = url.gsub(/\.git$/, "")
    url + ".git"
  end

  def clone_repository
    FileUtils.mkdir_p(clone_path.dirname)

    # Shallow clone for faster operation
    result = system(
      "git", "clone",
      "--depth", "1",
      "--single-branch",
      repository_url,
      clone_path.to_s,
      out: File::NULL,
      err: File::NULL
    )

    raise GitError, "Failed to clone repository: #{repository_url}" unless result
  end

  def cleanup
    FileUtils.rm_rf(clone_path) if clone_path && Dir.exist?(clone_path)
  end
end
