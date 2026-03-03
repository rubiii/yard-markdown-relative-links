# frozen_string_literal: true

require_relative 'lib/yard/relative_markdown_links/version'

Gem::Specification.new do |spec|
  spec.name = 'yard-markdown-relative-links'
  spec.version = YARD::RelativeMarkdownLinks::VERSION
  spec.authors = ['Daniel Harrington']
  spec.email = ['me@rubiii.com']

  spec.summary = 'A YARD plugin to convert relative links between Markdown files'
  spec.description = <<~DESC
    A YARD plugin that converts relative Markdown links to work in generated documentation.
    Supports files in subdirectories by resolving links relative to the current file's location.
    Works seamlessly with GitHub-style relative links while generating correct YARD file references.
  DESC
  spec.homepage = 'https://github.com/rubiii/yard-markdown-relative-links'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    Dir['{lib}/**/*', 'MIT-LICENSE', 'README.md', 'CHANGELOG.md'].reject { |f| File.directory?(f) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'yard', '>= 0.9', '< 1'
end
