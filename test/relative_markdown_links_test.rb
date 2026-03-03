# frozen_string_literal: true

require 'test_helper'

class RelativeMarkdownLinksTest < Minitest::Test
  class MockFile
    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end
  end

  class MockOptions
    attr_accessor :files, :file

    def initialize(files: [], file: nil)
      @files = files.map { |f| MockFile.new(f) }
      @file = file ? MockFile.new(file) : nil
    end

    def respond_to?(method, include_all = false)
      %i[files file].include?(method) || super
    end
  end

  # Base class that provides the superclass resolve_links method
  class BaseContext
    def resolve_links(text)
      text
    end
  end

  class TestContext < BaseContext
    include YARD::RelativeMarkdownLinks

    attr_accessor :options

    def initialize(options:, current_file: nil)
      @options = options
      @file = current_file ? MockFile.new(current_file) : nil
    end
  end

  def setup
    @files = %w[
      README.md
      docs/index.md
      docs/getting-started.md
      docs/configuration.md
      docs/guides/advanced.md
    ]
  end

  def test_converts_exact_path_match
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="docs/index.md">Documentation</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/index.md Documentation}'
  end

  def test_resolves_relative_link_from_subdirectory
    context = TestContext.new(
      options: MockOptions.new(files: @files),
      current_file: 'docs/index.md'
    )

    html = '<a href="getting-started.md">Getting Started</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/getting-started.md Getting Started}'
  end

  def test_resolves_link_with_parent_directory
    context = TestContext.new(
      options: MockOptions.new(files: @files),
      current_file: 'docs/guides/advanced.md'
    )

    html = '<a href="../configuration.md">Configuration</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/configuration.md Configuration}'
  end

  def test_preserves_fragment_anchor
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="docs/index.md#installation">Install</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/index.md#installation Install}'
  end

  def test_ignores_absolute_urls
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="https://example.com">Example</a>'
    result = context.resolve_links(html)

    assert_includes result, 'href="https://example.com"'
    refute_includes result, '{file:'
  end

  def test_ignores_links_with_query_string
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="docs/index.md?tab=overview">Docs</a>'
    result = context.resolve_links(html)

    assert_includes result, 'href="docs/index.md?tab=overview"'
    refute_includes result, '{file:'
  end

  def test_ignores_unknown_files
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="unknown.md">Unknown</a>'
    result = context.resolve_links(html)

    assert_includes result, 'href="unknown.md"'
    refute_includes result, '{file:'
  end

  def test_basename_fallback_with_unique_match
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    # getting-started.md only exists once in docs/
    html = '<a href="getting-started.md">Getting Started</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/getting-started.md Getting Started}'
  end

  def test_handles_empty_href
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="">Empty</a>'
    result = context.resolve_links(html)

    assert_includes result, 'href=""'
  end

  def test_handles_anchor_only_href
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="#section">Section</a>'
    result = context.resolve_links(html)

    assert_includes result, 'href="#section"'
  end

  def test_handles_multiple_links
    context = TestContext.new(
      options: MockOptions.new(files: @files),
      current_file: 'docs/index.md'
    )

    html = '<a href="getting-started.md">Start</a> and <a href="configuration.md">Config</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/getting-started.md Start}'
    assert_includes result, '{file:docs/configuration.md Config}'
  end

  def test_converts_single_quoted_href
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = "<a href='docs/index.md'>Documentation</a>"
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/index.md Documentation}'
  end

  def test_preserves_inner_html_in_converted_link
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="docs/index.md"><code>Documentation</code></a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/index.md <code>Documentation</code>}'
  end

  def test_converts_uppercase_anchor_tag
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<A HREF="docs/index.md">Documentation</A>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/index.md Documentation}'
  end

  def test_returns_unmodified_when_no_files
    options = MockOptions.new(files: [])
    options.instance_variable_set(:@files, nil)
    context = TestContext.new(options: options)

    html = '<a href="test.md">Test</a>'
    result = context.resolve_links(html)

    assert_includes result, 'href="test.md"'
  end

  def test_resolves_rdoc_style_html_filename
    # RDoc generates filenames like foo_bar_md.html for foo_bar.md
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="getting-started_md.html">Getting Started</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/getting-started.md Getting Started}'
  end

  def test_resolves_rdoc_style_with_directory
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="docs/configuration_md.html">Config</a>'
    result = context.resolve_links(html)

    assert_includes result, '{file:docs/configuration.md Config}'
  end

  def test_leaves_malformed_anchor_html_untouched
    context = TestContext.new(
      options: MockOptions.new(files: @files)
    )

    html = '<a href="docs/index.md">Documentation'
    result = context.resolve_links(html)

    assert_equal html, result
  end
end
