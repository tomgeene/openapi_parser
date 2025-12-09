defmodule OpenapiParser.Parser do
  @moduledoc """
  Main parser module for OpenAPI specifications.

  Handles parsing from strings and files, format detection, version detection,
  and delegates to version-specific parsers.
  """

  alias OpenapiParser.Parser.{V2, V3}
  alias OpenapiParser.Spec
  alias OpenapiParser.KeyNormalizer

  @doc """
  Parses an OpenAPI specification from a string.

  ## Options

  - `:format` - Format of the input (`:json`, `:yaml`, or `:auto`). Defaults to `:auto`
  - `:validate` - Whether to validate the parsed spec. Defaults to `true`
  - `:resolve_refs` - Whether to resolve $ref references. Defaults to `false`
  """
  @spec parse(String.t(), keyword()) :: {:ok, Spec.OpenAPI.t()} | {:error, String.t()}
  def parse(content, opts \\ []) do
    format = Keyword.get(opts, :format, :auto)
    validate = Keyword.get(opts, :validate, true)
    resolve_refs = Keyword.get(opts, :resolve_refs, false)

    with {:ok, data} <- decode_content(content, format),
         {:ok, version} <- detect_version(data),
         {:ok, spec} <- parse_version(version, data),
         {:ok, spec} <- maybe_resolve_refs(spec, resolve_refs),
         {:ok, spec} <- maybe_validate(spec, validate) do
      {:ok, spec}
    end
  end

  @doc """
  Parses an OpenAPI specification from a file.

  ## Options

  - `:format` - Format of the input (`:json`, `:yaml`, or `:auto`). Defaults to `:auto`
  - `:validate` - Whether to validate the parsed spec. Defaults to `true`
  - `:resolve_refs` - Whether to resolve $ref references. Defaults to `false`
  """
  @spec parse_file(String.t(), keyword()) :: {:ok, Spec.OpenAPI.t()} | {:error, String.t()}
  def parse_file(path, opts \\ []) do
    format = Keyword.get(opts, :format, :auto)

    with {:ok, content} <- File.read(path),
         format <- detect_format_from_path(path, format) do
      parse(content, Keyword.put(opts, :format, format))
    else
      {:error, reason} -> {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  # Private functions

  defp decode_content(content, :auto) do
    # Try JSON first, then YAML
    case Jason.decode(content) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> decode_yaml(content)
    end
  end

  defp decode_content(content, :json) do
    case Jason.decode(content) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, "JSON decode error: #{inspect(error)}"}
    end
  end

  defp decode_content(content, :yaml) do
    decode_yaml(content)
  end

  defp decode_yaml(content) do
    case YamlElixir.read_from_string(content) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, "YAML decode error: #{inspect(error)}"}
    end
  end

  defp detect_format_from_path(path, :auto) do
    case Path.extname(path) do
      ext when ext in [".yaml", ".yml"] -> :yaml
      ".json" -> :json
      _ -> :auto
    end
  end

  defp detect_format_from_path(_path, format), do: format

  defp detect_version(%{"swagger" => "2.0"}), do: {:ok, :v2}

  defp detect_version(%{"swagger" => version}),
    do: {:error, "Unsupported Swagger version: #{version}"}

  defp detect_version(%{"openapi" => version}) when is_binary(version) do
    case String.split(version, ".") do
      ["3", "0" | _] -> {:ok, :v3_0}
      ["3", "1" | _] -> {:ok, :v3_1}
      _ -> {:error, "Unsupported OpenAPI version: #{version}"}
    end
  end

  defp detect_version(_), do: {:error, "Missing version field (swagger or openapi)"}

  defp parse_version(:v2, data) do
    V2.parse(data)
  end

  defp parse_version(:v3_0, data) do
    V3.parse(data, :v3_0)
  end

  defp parse_version(:v3_1, data) do
    V3.parse(data, :v3_1)
  end

  defp maybe_resolve_refs(spec, false), do: {:ok, spec}

  defp maybe_resolve_refs(spec, true) do
    # Reference resolver currently always returns {:ok, spec}
    OpenapiParser.ReferenceResolver.resolve(spec)
  end

  defp maybe_validate(spec, false), do: {:ok, spec}

  defp maybe_validate(spec, true) do
    case Spec.OpenAPI.validate(spec) do
      :ok -> {:ok, spec}
      {:error, _} = error -> error
    end
  end
end
