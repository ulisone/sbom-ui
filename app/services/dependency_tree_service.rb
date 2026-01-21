# Builds a hierarchical tree structure from flat dependency list
class DependencyTreeService
  attr_reader :scan

  def initialize(scan:)
    @scan = scan
  end

  def build_tree
    return empty_tree unless scan

    dependencies = scan.dependencies.includes(:scan)
    vulnerabilities = scan.vulnerabilities.index_by(&:package_name)

    # Group by ecosystem
    by_ecosystem = dependencies.group_by(&:ecosystem)

    {
      name: scan.project.name,
      ecosystem: "project",
      children: by_ecosystem.map do |ecosystem, deps|
        build_ecosystem_node(ecosystem, deps, vulnerabilities)
      end
    }
  end

  def build_flat_tree
    return empty_tree unless scan

    dependencies = scan.dependencies.order(:ecosystem, :name)
    vulnerabilities = scan.vulnerabilities.index_by(&:package_name)

    {
      name: scan.project.name,
      ecosystem: "project",
      children: dependencies.map do |dep|
        build_dependency_node(dep, vulnerabilities[dep.name])
      end
    }
  end

  private

  def empty_tree
    {
      name: "No Dependencies",
      ecosystem: "none",
      children: []
    }
  end

  def build_ecosystem_node(ecosystem, dependencies, vulnerabilities)
    vulnerable_count = dependencies.count { |d| vulnerabilities[d.name].present? }

    {
      name: ecosystem || "Unknown",
      ecosystem: ecosystem,
      vulnCount: vulnerable_count,
      children: dependencies.map do |dep|
        build_dependency_node(dep, vulnerabilities[dep.name])
      end
    }
  end

  def build_dependency_node(dependency, vulnerability)
    node = {
      name: dependency.name,
      version: dependency.version,
      ecosystem: dependency.ecosystem,
      purl: dependency.purl,
      license: dependency.license,
      id: dependency.id
    }

    if vulnerability
      node[:vulnerable] = true
      node[:severity] = vulnerability.severity
      node[:cve_id] = vulnerability.cve_id
      node[:vulnCount] = 1
    else
      node[:vulnerable] = false
      node[:vulnCount] = 0
    end

    node
  end
end
