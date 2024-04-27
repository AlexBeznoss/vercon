# frozen_string_literal: true

require_relative "lib/vercon/version"

Gem::Specification.new do |spec|
  spec.name = "vercon"
  spec.version = Vercon::VERSION
  spec.authors = ["Alex Beznos"]
  spec.email = ["beznosa@yahoo.com"]

  spec.summary = "CLI tool to generate test files with Cloude 3"
  spec.description = "CLI tool to generate test files with Cloude 3."
  spec.homepage = "https://github.com/AlexBeznoss/vercon"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.required_rubygems_version = ">= 3.3.11"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = [spec.name]
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-cli", "~> 1.0", "< 2"
  spec.add_dependency "dry-files", "~> 1.0", "< 2"
  spec.add_dependency "httpx", "~> 1.2.3"
  spec.add_dependency "prism", "~> 0.24"
  spec.add_dependency "rouge", "~> 4.2.1"
  spec.add_dependency "tty-editor", "~> 0.7.0"
  spec.add_dependency "tty-prompt", "~> 0.23.1"
  spec.add_dependency "tty-spinner", "~> 0.9.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
