# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/tomgeene/openapi_parser/releases/tag/v0.1.0
