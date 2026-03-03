# frozen_string_literal: true

require 'nokogiri'
require 'uri'

require_relative 'relative_markdown_links/version'

module YARD
  # A YARD plugin to convert relative links between Markdown files.
  #
  # GitHub and YARD render Markdown files differently. In particular, relative
  # links in Markdown files that work in GitHub don't work in YARD. For example,
  # if you have `[hello](docs/FOO.md)` in your README, YARD renders it as
  # `<a href="docs/FOO.md">hello</a>`, creating a broken link in your docs.
  #
  # With this plugin enabled, you'll get `<a href="file.FOO.html">hello</a>`
  # instead, which correctly links through to the rendered HTML file.
  #
  # This plugin also properly handles files in subdirectories. For example,
  # if `docs/index.md` links to `getting-started.md`, the plugin resolves
  # the link relative to the current file's directory, finding
  # `docs/getting-started.md` in YARD's file list.
  module RelativeMarkdownLinks
    # Resolves relative links from Markdown files.
    #
    # @param text [String] the HTML fragment in which to resolve links
    # @return [String] HTML with relative links to extra files converted to `{file:}` links
    def resolve_links(text)
      return super unless options.files

      html = Nokogiri::HTML.fragment(text)
      html.css('a[href]').each do |link|
        process_link(link)
      end

      super(html.to_s)
    end

    private

    # Process a single link element, converting it to YARD file syntax if it matches a known file.
    #
    # @param link [Nokogiri::XML::Element] the anchor element to process
    # @return [void]
    def process_link(link)
      href = URI(link['href'])
      return unless href.relative?
      return if href.path.nil? || href.path.empty?

      resolved_path = resolve_file_path(href.path)
      return unless resolved_path

      # Preserve fragment/anchor if present
      file_ref = resolved_path
      file_ref = "#{file_ref}##{href.fragment}" if href.fragment

      link.replace("{file:#{file_ref} #{link.inner_html}}")
    rescue URI::InvalidURIError
      # Skip malformed URIs
      nil
    end

    # Resolve a relative file path to a known file in the YARD file list.
    #
    # @param path [String] the relative path from the link
    # @return [String, nil] the resolved path if found, nil otherwise
    def resolve_file_path(path)
      # Build lookup structures on first use
      @filenames ||= options.files.to_set(&:filename)
      @basename_to_paths ||= build_basename_mapping
      @rdoc_filenames ||= build_rdoc_filename_mapping
      @rdoc_basename_to_paths ||= build_rdoc_basename_mapping

      # First, try exact match (works for root-level files like docs/index.md from README)
      return path if @filenames.include?(path)

      # Try RDoc-style filename mapping (e.g., foo_bar_md.html -> foo_bar.md)
      rdoc_resolved = @rdoc_filenames[path]
      return rdoc_resolved if rdoc_resolved && @filenames.include?(rdoc_resolved)

      # Try RDoc-style basename-only matching
      rdoc_basename_resolved = resolve_rdoc_by_basename(path)
      return rdoc_basename_resolved if rdoc_basename_resolved

      # Try resolving relative to current file's directory
      resolved = resolve_relative_to_current_file(path)
      return resolved if resolved

      # Fallback: try to find by basename alone (for simple cases)
      resolve_by_basename(path)
    end

    # Resolve a path relative to the current file being processed.
    #
    # @param path [String] the relative path from the link
    # @return [String, nil] the resolved path if found, nil otherwise
    def resolve_relative_to_current_file(path)
      current_dir = current_file_directory
      return nil unless current_dir

      resolved = File.join(current_dir, path)
      resolved = normalize_path(resolved)
      resolved if @filenames.include?(resolved)
    end

    # Resolve a path by matching its basename against known files.
    #
    # @param path [String] the relative path from the link
    # @return [String, nil] the resolved path if exactly one match, nil otherwise
    def resolve_by_basename(path)
      basename = File.basename(path)
      candidates = @basename_to_paths[basename]
      candidates.first if candidates&.size == 1
    end

    # Get the directory of the current file being processed.
    #
    # @return [String, nil] the directory path, or nil if not available
    def current_file_directory
      # Try @file first (set in layout template)
      return File.dirname(@file.filename) if defined?(@file) && @file.respond_to?(:filename)

      # Try options.file (set during serialization)
      return File.dirname(options.file.filename) if options.respond_to?(:file) && options.file.respond_to?(:filename)

      nil
    end

    # Build a mapping from basename to full paths for fallback resolution.
    #
    # @return [Hash{String => Array<String>}] mapping of basenames to full paths
    def build_basename_mapping
      mapping = Hash.new { |h, k| h[k] = [] }
      options.files.each do |file|
        basename = File.basename(file.filename)
        mapping[basename] << file.filename
      end
      mapping
    end

    # Build a mapping from RDoc-style HTML filenames to original filenames.
    #
    # RDoc generates filenames like `foo_bar_md.html` for `foo_bar.md`.
    # This mapping allows resolving such links back to the original files.
    #
    # @return [Hash{String => String}] mapping of RDoc HTML names to original filenames
    # @see https://github.com/ruby/rdoc/blob/0e060c69f51ec4a877e5cde69b31d47eaeb2a2b9/lib/rdoc/markup/to_html.rb#L364-L366
    def build_rdoc_filename_mapping
      options.files.filter_map { |file|
        filename = file.filename
        match = %r{\A(?<dirname>(?:[^/#]*/)*+)(?<basename>[^/#]+)\.(?<ext>rb|rdoc|md)\z}i.match(filename)
        next unless match

        rdoc_name = "#{match[:dirname]}#{match[:basename].tr('.', '_')}_#{match[:ext]}.html"
        [rdoc_name, filename]
      }.to_h
    end

    # Build a mapping from RDoc-style basenames to original filenames.
    #
    # @return [Hash{String => Array<String>}] mapping of RDoc basenames to original filenames
    def build_rdoc_basename_mapping
      mapping = Hash.new { |h, k| h[k] = [] }
      options.files.each do |file|
        filename = file.filename
        match = %r{\A(?<dirname>(?:[^/#]*/)*+)(?<basename>[^/#]+)\.(?<ext>rb|rdoc|md)\z}i.match(filename)
        next unless match

        rdoc_basename = "#{match[:basename].tr('.', '_')}_#{match[:ext]}.html"
        mapping[rdoc_basename] << filename
      end
      mapping
    end

    # Resolve RDoc-style filename by basename alone.
    #
    # @param path [String] the RDoc-style HTML filename (e.g., getting-started_md.html)
    # @return [String, nil] the resolved path if exactly one match, nil otherwise
    def resolve_rdoc_by_basename(path)
      basename = File.basename(path)
      candidates = @rdoc_basename_to_paths[basename]
      candidates.first if candidates&.size == 1
    end

    # Normalize a file path, resolving . and .. components.
    #
    # @param path [String] the path to normalize
    # @return [String] the normalized path
    def normalize_path(path)
      parts = path.split('/')
      result = []

      parts.each do |part|
        case part
        when '.', ''
          # Skip current directory markers and empty parts
          next
        when '..'
          # Go up one directory
          result.pop
        else
          result << part
        end
      end

      result.join('/')
    end
  end

  Templates::Template.extra_includes << RelativeMarkdownLinks
end