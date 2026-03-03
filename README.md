# yard-relative_markdown_links

A YARD plugin to convert relative links between Markdown files.

GitHub and YARD render Markdown files differently. In particular, relative links in Markdown files that work in GitHub don't work in YARD. For example, if you have `[hello](FOO.md)` in your README, YARD renders it as `<a href="FOO.md">hello</a>`, creating a broken link in your docs.

With this plugin enabled, you'll get `<a href="file.FOO.html">hello</a>` instead, which correctly links through to the rendered HTML file.

## Features

- Converts relative Markdown links to YARD file references
- **Supports files in subdirectories** — links from `docs/index.md` to `getting-started.md` correctly resolve to `docs/getting-started.md`
- Preserves anchor/fragment links (e.g., `file.md#section`)
- Falls back to basename matching for simple cases
- No `Nokogiri` runtime dependency (stdlib-only link rewriting)

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'yard-relative_markdown_links'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install yard-relative_markdown_links
```

## Usage

Add this line to your application's `.yardopts`:

```
--plugin relative_markdown_links
```

You'll also need to make sure your Markdown files are processed by YARD. To include all Markdown files in your project, add the following lines to the end of your application's `.yardopts`:

```
-
**/*.md
```

### Example `.yardopts`

```
--markup markdown
--plugin relative_markdown_links
--readme README.md
-
docs/*.md
lib/**/*.rb
```

## How It Works

When YARD processes your Markdown files, this plugin intercepts the HTML output and converts relative links to YARD's `{file:}` syntax.

The plugin resolves links in three ways:

1. **Exact match** — If the link path exactly matches a file in YARD's file list (e.g., `docs/index.md`), it's used directly.

2. **Relative to current file** — If processing `docs/index.md` and it contains a link to `getting-started.md`, the plugin resolves this relative to the current file's directory, finding `docs/getting-started.md`.

3. **Basename fallback** — If there's exactly one file with the matching basename, it's used (e.g., `getting-started.md` matches `docs/getting-started.md` if that's the only file with that name).

## Background

### Origins

This gem is a replacement for the original [`yard-relative_markdown_links`](https://github.com/haines/yard-relative_markdown_links) gem created by Andrew Haines. The original gem was archived in February 2026.

The original gem solved an important problem: relative links between Markdown files that work on GitHub don't work in YARD-generated documentation. However, it had a limitation — it only matched links against exact file paths in YARD's file list, which meant links between files in subdirectories didn't work properly.

For example, if you had documentation in a `docs/` folder:

```
docs/
├── index.md        # contains [Getting Started](getting-started.md)
└── getting-started.md
```

The link in `index.md` would work on GitHub but not in YARD, because the original gem looked for `getting-started.md` in the file list, but YARD registered it as `docs/getting-started.md`.

### Comparison with the Original Gem

| Feature | Original | This Gem |
|---------|----------|----------|
| Convert exact path matches | ✅ | ✅ |
| Preserve fragment/anchors (`#section`) | ✅ | ✅ |
| Skip absolute URLs | ✅ | ✅ |
| RDoc filename mapping | ✅ | ✅ |
| **Subdirectory support** | ❌ | ✅ |
| **Parent directory (`..`) resolution** | ❌ | ✅ |
| **Basename fallback matching** | ❌ | ✅ |
| **Malformed URI handling** | ❌ | ✅ |

### Key Improvements

1. **Subdirectory support** — When processing `docs/index.md`, a link to `getting-started.md` is resolved relative to the current file's directory, correctly finding `docs/getting-started.md`.

2. **Parent directory resolution** — Links like `../other-file.md` are normalized and resolved correctly.

3. **Basename fallback** — If there's exactly one file with a matching basename, it's used even without the full path.

4. **Error handling** — Malformed URIs are gracefully skipped instead of raising exceptions.

## Development

Run tests:

```sh
bundle exec rake test
```

Run linting:

```sh
bundle exec rake lint
```

## License

Released under the [MIT License](LICENSE.txt).
