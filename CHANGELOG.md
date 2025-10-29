# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for `--warnings-as-errors` command line flag
- Respect `warnings_as_errors` setting in `elixirc_options`
- Package publishing configuration for Hex.pm
- Enhanced module documentation with comprehensive examples
- README badges for version, documentation, license, and build status
- Proper OptionParser integration for command line argument parsing

### Fixed
- Fixed transitive module access through public modules
- Improved private module identification to only tag modules that actually use `PrivateModule`
- Fixed access control logic to properly allow calls to non-private modules
- Private module tagging now uses function-based approach instead of attributes

### Changed
- Private module violations now respect warnings-as-errors configuration instead of always failing compilation
- README updated with minimal essential documentation
- Enhanced @moduledoc with detailed usage examples and API documentation

## [0.1.0] - 2024-12-19

### Added
- Initial release of PrivateModule library
- Core functionality to mark modules as private using `use PrivateModule`
- Compile-time enforcement of privacy rules
- Custom Mix compiler task for dependency tracking
- Comprehensive error messages for privacy violations
- Support for nested private modules
- Documentation and examples
- Test suite with comprehensive coverage

### Features
- Private modules can only be called from their parent module
- Compile-time validation prevents privacy violations
- Clear error messages indicating where violations occur
- Runtime-free dependency (compilation only)
- Compatible with standard Elixir tooling (ExDoc, Dialyzer, Credo)

[0.1.0]: https://github.com/bit4bit/private_module/releases/tag/v0.1.0