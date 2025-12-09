defmodule OpenapiParser.KeyNormalizer do
  @moduledoc """
  Utility module for normalizing map keys from strings to atoms.
  
  This ensures consistent key format throughout the parsed OpenAPI specification,
  eliminating the need for defensive code that checks both atom and string variants.
  """

  @doc """
  Normalizes the top-level keys of a map to atoms without recursion.
  
  This is useful for spec constructors that receive data directly.
  """
  @spec normalize_shallow(map()) :: map()
  def normalize_shallow(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      {normalize_key(key), value}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Recursively converts all string keys in a map to atoms.
  
  This function handles nested maps and lists of maps, ensuring all string keys
  are converted to atoms for consistent access patterns.
  
  ## Safety
  
  Only known OpenAPI/Swagger keys are converted to atoms to prevent atom table exhaustion.
  Unknown keys are kept as strings for safety.
  
  ## Examples
  
      iex> normalize(%{"name" => "test", "nested" => %{"key" => "value"}})
      %{name: "test", nested: %{key: "value"}}
      
      iex> normalize(%{"items" => [%{"type" => "string"}]})
      %{items: [%{type: "string"}]}
  """
  @spec normalize(map() | list() | any()) :: map() | list() | any()
  def normalize(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      {normalize_key(key), normalize(value)}
    end)
    |> Enum.into(%{})
  end

  def normalize(list) when is_list(list) do
    Enum.map(list, &normalize/1)
  end

  def normalize(value), do: value

  # Known OpenAPI/Swagger keys that should be converted to atoms
  # This list includes all standard fields across all OpenAPI versions
  @known_keys MapSet.new([
    # Version fields
    "swagger", "openapi",
    # Common metadata
    "info", "title", "version", "summary", "description", "termsOfService",
    "contact", "name", "url", "email",
    "license", "identifier",
    # Server/host fields
    "servers", "server", "host", "basePath", "schemes", "variables",
    "enum", "default",
    # Paths and operations
    "paths", "get", "put", "post", "delete", "options", "head", "patch", "trace",
    "parameters", "parameter", "in", "required", "deprecated", "allowEmptyValue",
    "style", "explode", "allowReserved", "schema", "example", "examples",
    "content", "encoding", "contentType",
    # Request/Response
    "requestBody", "responses", "headers", "links", "callbacks",
    # Schema fields
    "type", "format", "properties", "items", "additionalProperties",
    "patternProperties", "propertyNames", "unevaluatedProperties", "unevaluatedItems",
    "allOf", "anyOf", "oneOf", "not", "if", "then", "else",
    "prefixItems", "contains", "minContains", "maxContains",
    "dependentSchemas", "const",
    # Validation keywords
    "maximum", "minimum", "exclusiveMaximum", "exclusiveMinimum", "multipleOf",
    "maxLength", "minLength", "pattern",
    "maxItems", "minItems", "uniqueItems",
    "maxProperties", "minProperties",
    # Metadata
    "externalDocs", "tags", "operationId", "consumes", "produces",
    # Security
    "security", "securitySchemes", "securityDefinitions", "scheme",
    "bearerFormat", "flows", "implicit", "password", "clientCredentials",
    "authorizationCode", "authorizationUrl", "tokenUrl", "refreshUrl", "scopes",
    "openIdConnectUrl",
    # Components
    "components", "schemas", "requestBodies", "securitySchemes",
    # References
    "$ref", "$id", "$schema", "$anchor", "$dynamicAnchor", "$dynamicRef",
    "$comment", "$defs",
    # OpenAPI specific
    "discriminator", "readOnly", "writeOnly", "xml", "namespace", "prefix",
    "attribute", "wrapped", "nullable",
    # V3 specific
    "contentEncoding", "contentMediaType", "contentSchema",
    # Media type
    "mediaType",
    # Link fields
    "operationRef", "operationId",
    # Encoding
    "headers",
    # Path item
    "summary",
    # V2 specific
    "collectionFormat", "location", "flow",
    # External value
    "externalValue", "value",
    # Mapping
    "mapping", "propertyName",
    # OAuth
    "authorizationUrl"
  ])

  defp normalize_key(key) when is_binary(key) do
    if MapSet.member?(@known_keys, key) do
      # For keys starting with $, we need to use the :"$key" syntax
      if String.starts_with?(key, "$") do
        String.to_atom(key)
      else
        String.to_atom(key)
      end
    else
      # Keep unknown keys as strings to avoid atom table exhaustion
      key
    end
  end

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key), do: key
end
