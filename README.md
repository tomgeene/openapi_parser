# OpenapiParser

[![CI](https://github.com/tomgeene/openapi_parser/actions/workflows/ci.yml/badge.svg)](https://github.com/tomgeene/openapi_parser/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/openapi_parser.svg)](https://hex.pm/packages/openapi_parser)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/openapi_parser)

> **Note**: This library was primarily created with AI assistance. As with any external library, please use it with caution and verify its behavior in your specific use case before deploying to production.

A comprehensive OpenAPI specification parser for Elixir that supports:

- **OpenAPI 2.0** (Swagger)
- **OpenAPI 3.0**
- **OpenAPI 3.1**

Both **JSON** and **YAML** formats are supported with full validation.

## Features

- ✅ **Complete OpenAPI Support** - Parse all three major versions
- ✅ **Full JSON Schema 2020-12** - Complete support for OpenAPI 3.1 schema features
- ✅ **Format Flexible** - JSON and YAML with auto-detection
- ✅ **Comprehensive Validation** - Validates required fields, types, formats, and semantic rules
- ✅ **Type Safe** - Full Elixir typespecs for all structs
- ✅ **Well Tested** - Extensive test coverage (450+ tests)

## Installation

Add `openapi_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:openapi_parser, "~> 0.2.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

```elixir
# Parse from a string
{:ok, spec} = OpenapiParser.parse(json_string, format: :json)
{:ok, spec} = OpenapiParser.parse(yaml_string, format: :yaml)

# Parse from a file (auto-detects format)
{:ok, spec} = OpenapiParser.parse_file("openapi.json")
{:ok, spec} = OpenapiParser.parse_file("swagger.yaml")

# Access parsed data
IO.puts(spec.document.info.title)
IO.puts(spec.document.info.version)
```

## Parsing Options

- `:format` - Input format (`:json`, `:yaml`, or `:auto`). Default: `:auto`
- `:validate` - Whether to validate the spec. Default: `:true`
- `:resolve_refs` - Whether to resolve `$ref` references. Default: `:false`

```elixir
# Parse without validation (faster)
{:ok, spec} = OpenapiParser.parse(content, validate: false)

# Parse with reference resolution
{:ok, spec} = OpenapiParser.parse_file("spec.yaml", resolve_refs: true)
```

## Supported Specifications

### OpenAPI 3.1

- Full JSON Schema 2020-12 support including:
  - `patternProperties`, `propertyNames`, `unevaluatedItems`, `unevaluatedProperties`
  - `prefixItems`, `contains`, `minContains`, `maxContains`
  - `dependentSchemas`, `if`/`then`/`else` conditional validation
  - `$defs`, `$id`, `$anchor`, `$dynamicAnchor`, `$dynamicRef`, `$schema`, `$comment`
- Webhooks support
- Info `summary` field
- Type arrays (e.g., `type: ["string", "null"]`)
- License `identifier` field

### OpenAPI 3.0

- Components (schemas, responses, parameters, etc.)
- Request bodies with multiple content types
- Callbacks and links
- Discriminators
- Security schemes (apiKey, http, oauth2, openIdConnect)
- Server variables
- Cookie parameters
- `nullable` field support

### Swagger 2.0

- Definitions
- Global parameters and responses
- Parameters (including formData and file types)
- Responses with headers
- Security definitions
- Global consumes/produces
- Collection formats

## Error Handling

```elixir
case OpenapiParser.parse(invalid_spec, validate: true) do
  {:ok, spec} ->
    IO.puts("Valid spec!")

  {:error, message} ->
    IO.puts("Validation error: #{message}")
end
```

## Resources

- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [Swagger 2.0 Specification](https://swagger.io/specification/v2/)
- [Hex Package](https://hex.pm/packages/openapi_parser)
- [Documentation](https://hexdocs.pm/openapi_parser)
- [Changelog](CHANGELOG.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
