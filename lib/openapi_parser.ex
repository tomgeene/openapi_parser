defmodule OpenapiParser do
  @moduledoc """
  A comprehensive OpenAPI specification parser for Elixir.

  OpenapiParser supports parsing and validating OpenAPI 2.0 (Swagger), 3.0, and 3.1
  specifications in both JSON and YAML formats.

  ## Features

  - **Multiple Versions**: Supports OpenAPI 3.1, 3.0, and Swagger 2.0
  - **Format Flexible**: Parse JSON and YAML with automatic format detection
  - **Comprehensive Validation**: Validates required fields, types, formats, and semantic rules
  - **Type Safe**: Full Elixir typespecs for all structs
  - **Production Ready**: Thoroughly tested with edge cases and boundary values

  ## Quick Start

      # Parse from a string
      {:ok, spec} = OpenapiParser.parse(json_string, format: :json)
      {:ok, spec} = OpenapiParser.parse(yaml_string, format: :yaml)

      # Parse from a file (auto-detects format)
      {:ok, spec} = OpenapiParser.parse_file("openapi.json")
      {:ok, spec} = OpenapiParser.parse_file("swagger.yaml")

      # Access parsed data
      IO.puts(spec.document.info.title)
      IO.puts(spec.document.info.version)

  ## Parsing Options

  All parsing functions accept the following options:

  - `:format` - Input format (`:json`, `:yaml`, or `:auto`). Default: `:auto`
  - `:validate` - Whether to validate the spec. Default: `true`
  - `:resolve_refs` - Whether to resolve `$ref` references. Default: `false`

  ## Examples

      # Parse without validation (faster)
      {:ok, spec} = OpenapiParser.parse(content, validate: false)

      # Parse with reference resolution
      {:ok, spec} = OpenapiParser.parse_file("spec.yaml", resolve_refs: true)

      # Explicit format specification
      {:ok, spec} = OpenapiParser.parse(content, format: :json, validate: true)

  ## Working with Parsed Specs

      {:ok, spec} = OpenapiParser.parse_file("openapi.yaml")

      # Check version
      case spec.version do
        :v2 -> IO.puts("Swagger 2.0")
        :v3_0 -> IO.puts("OpenAPI 3.0")
        :v3_1 -> IO.puts("OpenAPI 3.1")
      end

      # Access spec information
      info = spec.document.info
      IO.puts("API: \#{info.title} v\#{info.version}")

      # Iterate over paths
      Enum.each(spec.document.paths, fn {path, path_item} ->
        IO.puts("Path: \#{path}")
        if path_item.get, do: IO.puts("  - GET")
        if path_item.post, do: IO.puts("  - POST")
      end)

      # Access schemas (OpenAPI 3.x)
      if spec.document.components do
        Enum.each(spec.document.components.schemas, fn {name, schema} ->
          IO.puts("Schema: \#{name} (type: \#{schema.type})")
        end)
      end

  ## Error Handling

      case OpenapiParser.parse(content) do
        {:ok, spec} ->
          # Successfully parsed and validated
          process_spec(spec)

        {:error, message} ->
          # Parsing or validation error
          IO.puts("Error: \#{message}")
      end

  ## Building an API Client

      defmodule MyAPIClient do
        def from_spec(spec_path) do
          {:ok, spec} = OpenapiParser.parse_file(spec_path)

          base_url = get_base_url(spec)
          operations = extract_operations(spec.document.paths)

          %{base_url: base_url, operations: operations}
        end

        defp get_base_url(spec) do
          case spec.version do
            :v2 ->
              scheme = List.first(spec.document.schemes) || "https"
              "\#{scheme}://\#{spec.document.host}\#{spec.document.base_path}"
            _ ->
              List.first(spec.document.servers).url
          end
        end
      end

  ## Validation

  The parser performs comprehensive validation including:

  - Required fields validation
  - Type checking (string, integer, boolean, array, object, etc.)
  - Format validation (email, uri, url, uuid, date, date-time, etc.)
  - Enum and pattern validation
  - Semantic rules (e.g., path parameters must be required)
  - HTTP status code validation
  - Content-type validation

  Validation errors include detailed field paths:

      {:error, "paths./users.get.parameters[0]: Path parameter must be required"}
  """

  alias OpenapiParser.Parser

  @doc """
  Parses an OpenAPI specification from a string.

  ## Options

  - `:format` - Format of the input (`:json`, `:yaml`, or `:auto`). Defaults to `:auto`
  - `:validate` - Whether to validate the parsed spec. Defaults to `true`
  - `:resolve_refs` - Whether to resolve $ref references. Defaults to `false`

  ## Examples

      iex> spec = ~s({"openapi":"3.1.0","info":{"title":"Test","version":"1.0.0"},"paths":{"/test":{"get":{"responses":{"200":{"description":"OK"}}}}}})
      iex> result = OpenapiParser.parse(spec, format: :json)
      iex> match?({:ok, %OpenapiParser.Spec.OpenAPI{}}, result)
      true
  """
  @spec parse(String.t(), keyword()) ::
          {:ok, OpenapiParser.Spec.OpenAPI.t()} | {:error, String.t()}
  def parse(content, opts \\ []), do: Parser.parse(content, opts)

  @doc """
  Parses an OpenAPI specification from a file.

  ## Examples

      iex> result = OpenapiParser.parse_file("test/fixtures/openapi_3.1.json")
      iex> match?({:ok, %OpenapiParser.Spec.OpenAPI{}}, result)
      true
  """
  @spec parse_file(String.t(), keyword()) ::
          {:ok, OpenapiParser.Spec.OpenAPI.t()} | {:error, String.t()}
  def parse_file(path, opts \\ []), do: Parser.parse_file(path, opts)
end
