# OpenapiParser

[![CI](https://github.com/tomgeene/openapi_parser/actions/workflows/ci.yml/badge.svg)](https://github.com/tomgeene/openapi_parser/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/openapi_parser.svg)](https://hex.pm/packages/openapi_parser)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/openapi_parser)

A comprehensive OpenAPI specification parser for Elixir that supports:

- **OpenAPI 2.0** (Swagger)
- **OpenAPI 3.0**
- **OpenAPI 3.1**

Both **JSON** and **YAML** formats are supported with full validation.

## Features

- ✅ **Complete OpenAPI Support** - Parse all three major versions
- ✅ **Format Flexible** - JSON and YAML with auto-detection
- ✅ **Comprehensive Validation** - Validates required fields, types, formats, and semantic rules
- ✅ **Type Safe** - Full Elixir typespecs for all structs
- ✅ **Well Tested** - Extensive test coverage with boundary value testing
- ✅ **Production Ready** - Used for building API clients, documentation generators, and validation tools

## Installation

Add `openapi_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:openapi_parser, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

### Parse from a String

```elixir
# Parse JSON
json_spec = """
{
  "openapi": "3.1.0",
  "info": {
    "title": "My API",
    "version": "1.0.0"
  },
  "paths": {
    "/users": {
      "get": {
        "responses": {
          "200": {
            "description": "Success"
          }
        }
      }
    }
  }
}
"""

{:ok, spec} = OpenapiParser.parse(json_spec, format: :json)
# => {:ok, %OpenapiParser.Spec.OpenAPI{version: :v3_1, document: ...}}

# Parse YAML
yaml_spec = """
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
paths:
  /users:
    get:
      responses:
        '200':
          description: Success
"""

{:ok, spec} = OpenapiParser.parse(yaml_spec, format: :yaml)
```

### Parse from a File

```elixir
# Auto-detects format from file extension
{:ok, spec} = OpenapiParser.parse_file("openapi.json")
{:ok, spec} = OpenapiParser.parse_file("swagger.yaml")

# Access the parsed data
IO.puts(spec.document.info.title)
# => "My API"

IO.puts(spec.document.info.version)
# => "1.0.0"
```

## Parsing Options

All parsing functions accept the following options:

- `:format` - Input format (`:json`, `:yaml`, or `:auto`). Default: `:auto`
- `:validate` - Whether to validate the spec. Default: `true`
- `:resolve_refs` - Whether to resolve `$ref` references. Default: `false`

```elixir
# Parse without validation (faster, but may accept invalid specs)
{:ok, spec} = OpenapiParser.parse(content, validate: false)

# Parse with reference resolution
{:ok, spec} = OpenapiParser.parse_file("spec.yaml", resolve_refs: true)

# Explicit format
{:ok, spec} = OpenapiParser.parse(content, format: :json, validate: true)
```

## Working with Parsed Specs

### Access Spec Information

```elixir
{:ok, spec} = OpenapiParser.parse_file("openapi.yaml")

# Check version
case spec.version do
  :v2 -> IO.puts("Swagger 2.0")
  :v3_0 -> IO.puts("OpenAPI 3.0")
  :v3_1 -> IO.puts("OpenAPI 3.1")
end

# Access info
info = spec.document.info
IO.puts("Title: #{info.title}")
IO.puts("Version: #{info.version}")
IO.puts("Description: #{info.description}")

# Access contact information
if info.contact do
  IO.puts("Contact: #{info.contact.name}")
  IO.puts("Email: #{info.contact.email}")
end

# Access license
if info.license do
  IO.puts("License: #{info.license.name}")
end
```

### Iterate Over Paths

```elixir
{:ok, spec} = OpenapiParser.parse_file("openapi.yaml")

# List all paths
Enum.each(spec.document.paths, fn {path, path_item} ->
  IO.puts("Path: #{path}")

  # Check which HTTP methods are defined
  if path_item.get, do: IO.puts("  - GET")
  if path_item.post, do: IO.puts("  - POST")
  if path_item.put, do: IO.puts("  - PUT")
  if path_item.delete, do: IO.puts("  - DELETE")
end)
```

### Access Operation Details

```elixir
{:ok, spec} = OpenapiParser.parse_file("openapi.yaml")

# Get a specific path
path_item = spec.document.paths["/users/{id}"]

# Access GET operation
if path_item.get do
  operation = path_item.get

  IO.puts("Operation ID: #{operation.operation_id}")
  IO.puts("Summary: #{operation.summary}")
  IO.puts("Tags: #{inspect(operation.tags)}")

  # List parameters
  if operation.parameters do
    Enum.each(operation.parameters, fn param ->
      IO.puts("Parameter: #{param.name} (#{param.location})")
      IO.puts("  Required: #{param.required}")
    end)
  end

  # List responses
  Enum.each(operation.responses.responses, fn {status, response} ->
    IO.puts("Response #{status}: #{response.description}")
  end)
end
```

### Access Components/Schemas

```elixir
{:ok, spec} = OpenapiParser.parse_file("openapi.yaml")

# For OpenAPI 3.x
if spec.document.components do
  schemas = spec.document.components.schemas

  Enum.each(schemas, fn {name, schema} ->
    IO.puts("Schema: #{name}")
    IO.puts("  Type: #{schema.type}")

    if schema.properties do
      IO.puts("  Properties:")
      Enum.each(schema.properties, fn {prop_name, prop_schema} ->
        IO.puts("    - #{prop_name}: #{prop_schema.type}")
      end)
    end
  end)
end

# For Swagger 2.0
if spec.version == :v2 and spec.document.definitions do
  Enum.each(spec.document.definitions, fn {name, schema} ->
    IO.puts("Definition: #{name}")
  end)
end
```

## Building an API Client

Here's a practical example of using the parser to build an API client:

```elixir
defmodule MyAPIClient do
  def build_from_spec(spec_path) do
    {:ok, spec} = OpenapiParser.parse_file(spec_path, validate: true)

    # Extract server URL
    server_url = case spec.version do
      :v2 ->
        scheme = List.first(spec.document.schemes) || "https"
        "#{scheme}://#{spec.document.host}#{spec.document.base_path}"
      _ ->
        List.first(spec.document.servers).url
    end

    # Build client functions for each operation
    operations = extract_operations(spec.document.paths)

    %{
      base_url: server_url,
      operations: operations,
      info: spec.document.info
    }
  end

  defp extract_operations(paths) do
    Enum.flat_map(paths, fn {path, path_item} ->
      [:get, :post, :put, :delete, :patch]
      |> Enum.filter(&Map.get(path_item, &1))
      |> Enum.map(fn method ->
        operation = Map.get(path_item, method)
        %{
          method: method,
          path: path,
          operation_id: operation.operation_id,
          summary: operation.summary,
          parameters: operation.parameters || []
        }
      end)
    end)
  end
end

# Use it
client = MyAPIClient.build_from_spec("api_spec.yaml")
IO.puts("API: #{client.info.title}")
IO.puts("Base URL: #{client.base_url}")
IO.puts("Available operations: #{length(client.operations)}")
```

## Validation

The parser performs comprehensive validation including:

- **Required fields** - Ensures all required fields are present
- **Type checking** - Validates field types (string, integer, boolean, etc.)
- **Format validation** - Validates string formats (email, uri, url, uuid, etc.)
- **Enum validation** - Checks enumerated values
- **Semantic rules** - e.g., path parameters must be required, paths must start with "/"
- **HTTP status codes** - Validates status code formats
- **Content types** - Validates media type formats

### Handling Validation Errors

```elixir
case OpenapiParser.parse(invalid_spec, validate: true) do
  {:ok, spec} ->
    IO.puts("Valid spec!")

  {:error, message} ->
    IO.puts("Validation error: #{message}")
    # Example: "paths./users.get.parameters[0]: Path parameter must be required"
end
```

## Supported Specifications

### OpenAPI 3.1

- Full JSON Schema 2020-12 support
- Type arrays (e.g., `type: ["string", "null"]`)
- `const` keyword
- License `identifier` field
- And all OpenAPI 3.0 features

### OpenAPI 3.0

- Components (schemas, responses, parameters, etc.)
- Request bodies with multiple content types
- Callbacks and links
- Discriminators
- Security schemes (apiKey, http, oauth2, openIdConnect)
- Server variables
- Cookie parameters

### Swagger 2.0

- Definitions
- Parameters (including formData and file types)
- Responses with headers
- Security definitions
- Global consumes/produces
- Collection formats

## Error Handling

```elixir
# File not found
{:error, message} = OpenapiParser.parse_file("nonexistent.yaml")

# Invalid JSON/YAML
{:error, message} = OpenapiParser.parse("{invalid json", format: :json)

# Missing version
{:error, message} = OpenapiParser.parse("""
{
  "info": {"title": "API", "version": "1.0.0"},
  "paths": {}
}
""")
# => {:error, "Missing version field (swagger or openapi)"}

# Validation errors
{:error, message} = OpenapiParser.parse("""
{
  "openapi": "3.0.0",
  "info": {"title": "API", "version": "1.0.0"}
}
""", validate: true)
# => {:error, "paths is required"}
```

## Advanced Usage

### Custom Validation

```elixir
defmodule MyValidator do
  def validate_custom_rules(spec) do
    with {:ok, spec} <- OpenapiParser.parse_file("spec.yaml"),
         :ok <- validate_operation_ids(spec),
         :ok <- validate_descriptions(spec) do
      {:ok, spec}
    end
  end

  defp validate_operation_ids(spec) do
    operations = extract_all_operations(spec.document.paths)
    operation_ids = Enum.map(operations, & &1.operation_id)

    if length(operation_ids) == length(Enum.uniq(operation_ids)) do
      :ok
    else
      {:error, "Duplicate operation IDs found"}
    end
  end

  defp validate_descriptions(spec) do
    # Ensure all operations have descriptions
    # ... custom validation logic
    :ok
  end
end
```

### Generating Documentation

```elixir
defmodule DocGenerator do
  def generate_markdown(spec_path) do
    {:ok, spec} = OpenapiParser.parse_file(spec_path)

    """
    # #{spec.document.info.title}

    Version: #{spec.document.info.version}

    #{spec.document.info.description}

    ## Endpoints

    #{generate_paths_doc(spec.document.paths)}
    """
  end

  defp generate_paths_doc(paths) do
    paths
    |> Enum.map(fn {path, path_item} ->
      generate_path_doc(path, path_item)
    end)
    |> Enum.join("\n\n")
  end

  defp generate_path_doc(path, path_item) do
    """
    ### #{path}

    #{generate_operations_doc(path_item)}
    """
  end

  defp generate_operations_doc(path_item) do
    [:get, :post, :put, :delete]
    |> Enum.filter(&Map.get(path_item, &1))
    |> Enum.map(fn method ->
      operation = Map.get(path_item, method)
      "- **#{String.upcase(to_string(method))}**: #{operation.summary || operation.description}"
    end)
    |> Enum.join("\n")
  end
end
```

## Performance Considerations

- **Parsing** is generally fast, even for large specifications (10,000+ lines)
- **Validation** adds ~20-30% overhead
- **Reference resolution** can be expensive for deeply nested references
- For best performance: parse once, cache the result

```elixir
# Good: Parse once
{:ok, spec} = OpenapiParser.parse_file("spec.yaml")
# Use spec multiple times...

# Avoid: Parsing repeatedly
Enum.each(1..100, fn _ ->
  {:ok, spec} = OpenapiParser.parse_file("spec.yaml")  # Don't do this!
end)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Resources

- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [Swagger 2.0 Specification](https://swagger.io/specification/v2/)
- [Hex Package](https://hex.pm/packages/openapi_parser)
- [Documentation](https://hexdocs.pm/openapi_parser)
