# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-12-08

### Added

- **JSON Schema 2020-12 Keywords** - Full support for all JSON Schema 2020-12 features:
  - `patternProperties` - Pattern-based property validation
  - `propertyNames` - Property name validation
  - `prefixItems` - Tuple-style array validation
  - `contains` / `minContains` / `maxContains` - Array containment validation
  - `unevaluatedItems` - Array item validation
  - `unevaluatedProperties` - Object property validation (previously missing)
  - `dependentSchemas` - Conditional schemas based on property presence
  - `if` / `then` / `else` - Conditional schema validation
  - `$defs` - Local schema definitions
  - `$id`, `$anchor`, `$dynamicAnchor`, `$dynamicRef` - Schema references
  - `$schema` - JSON Schema version declaration
  - `$comment` - Documentation comments
- **OpenAPI 3.1 Features**:
  - `webhooks` - Top-level webhooks object support
  - `summary` - Info object summary field
  - Fixed validation to allow specs with only `webhooks` or only `components` (OpenAPI 3.1 requirement)
- **OpenAPI 3.0 Compatibility**:
  - `nullable` - Nullable field support for OpenAPI 3.0
- **Swagger 2.0**:
  - Global `parameters` - Parsing and validation of root-level parameters
  - Global `responses` - Parsing and validation of root-level responses
- Comprehensive test suite with 450+ tests covering all new features
- Integration tests for all new JSON Schema keywords and OpenAPI features

### Changed

- Updated validation logic to support OpenAPI 3.1 requirements (paths/components/webhooks)
- Enhanced schema validation to support all JSON Schema 2020-12 keywords
- Test suite expanded from 417 tests to 451 tests

## [0.1.2] - 2025-12-08

### Added

- Comprehensive test coverage improvements (85.60% → 90.14%)
- New test files for improved module coverage:
  - `security_requirement_test.exs` - V2/V3 SecurityRequirement tests
  - `v3_link_test.exs` - V3.Link server parsing and validation tests
  - `v3_operation_test.exs` - V3.Operation callbacks, security, and validation tests
  - `v3_example_reference_test.exs` - V3.Example and V3.Reference tests
- Extended tests for V3.Header examples parsing and validation
- Extended tests for V3.Parameter content and examples branches
- Extended tests for V3.Encoding header validation
- Extended tests for Parser.V2/V3 error paths

### Changed

- Test suite expanded from ~320 tests to 417 tests

## [0.1.1] - 2025-12-08

### Fixed

- Fixed all Dialyzer warnings by adding fallback clauses to `new/1` functions
- Added proper error handling for non-map inputs in spec parsers

### Added

- Added `dialyxir` as a dev dependency for static analysis

## [0.1.0] - 2025-11-22

### Added

- Initial release of OpenapiParser
- Full support for OpenAPI 3.1, 3.0, and Swagger 2.0 specifications
- JSON and YAML format support with auto-detection
- Comprehensive validation for all specification versions
- Type-safe Elixir structs for all OpenAPI objects
- Validation module with reusable validation functions
- Detailed error messages with field path context
- Support for:
  - All HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, TRACE)
  - Path, query, header, and cookie parameters
  - Request bodies with multiple content types
  - Response objects with headers, links, and callbacks
  - Components/definitions for reusable objects
  - Security schemes (apiKey, http, oauth2, openIdConnect)
  - Discriminators and polymorphism
  - Server objects with variables
  - External documentation and tags
  - Schema composition (allOf, anyOf, oneOf, not)
  - All JSON Schema validation keywords
- Comprehensive test suite with 30+ tests
- Test fixtures covering edge cases and boundary values

### Validation Features

- Required field validation
- Type checking (string, integer, number, boolean, array, object)
- Format validation (email, uri, url, uuid, date, date-time, etc.)
- Enum validation
- Pattern matching (regex)
- Number constraints (minimum, maximum, multipleOf, exclusive min/max)
- String constraints (minLength, maxLength, pattern)
- Array constraints (minItems, maxItems, uniqueItems)
- Object constraints (minProperties, maxProperties, required, additionalProperties)
- HTTP status code validation
- Path format validation (must start with "/")
- Path parameter validation (must be required)
- Content-type validation
- Reference format validation

### Documentation

- Comprehensive README with usage examples
- API documentation with examples
- Module grouping for easy navigation
- Real-world usage examples (API clients, documentation generators)

[0.2.0]: https://github.com/tomgeene/openapi_parser/releases/tag/v0.2.0
[0.1.2]: https://github.com/tomgeene/openapi_parser/releases/tag/v0.1.2
[0.1.1]: https://github.com/tomgeene/openapi_parser/releases/tag/v0.1.1
[0.1.0]: https://github.com/tomgeene/openapi_parser/releases/tag/v0.1.0
