# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-03

### Changed

- Replaced `Nokogiri` with a stdlib-only anchor rewriter for link conversion
- Refactored file lookup caching to rebuild indexes when YARD file lists change

### Added

- Test coverage for uppercase/single-quoted anchors and malformed HTML fragments

## [0.1.0] - 2026-03-03

### Added

- Initial release
- Convert relative Markdown links to YARD file references
- Support for files in subdirectories by resolving links relative to the current file's directory
- Preserve anchor/fragment links (e.g., `file.md#section`)
- Basename fallback matching when there's exactly one file with the matching name
