# frozen_string_literal: true

require_relative "lib/ambassadors/pagination/version"

Gem::Specification.new do |spec|
  spec.name = "ambassadors-pagination"
  spec.version = Ambassadors::Pagination::VERSION
  spec.authors = ["Cleo AI"]
  spec.email = ["gavin@meetcleo.com"]

  spec.summary = "Kaminari pagination for ambassador collections."
  spec.description = <<~STRING
    Extends AmbassadorCollection with Kaminari-backed pagination and metadata,
    while preserving the load limits that prevent large result sets being
    materialised at once.
  STRING
  spec.homepage = "https://github.com/meetcleo/ambassadors-pagination"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |path|
      path.start_with?("test/", ".git", ".github") ||
        %w[Gemfile Gemfile.lock Rakefile].include?(path)
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "ambassadors"
  spec.add_dependency "kaminari", "~> 1.2"
end
