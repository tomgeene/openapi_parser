defmodule OpenapiParser.Validation do
  @moduledoc """
  Common validation functions used across OpenAPI specification structs.

  Provides reusable validation logic with detailed error messages including field paths.
  """

  @doc """
  Validates that required fields exist in a struct.

  Returns :ok if all required fields are present and not nil, otherwise returns an error.
  """
  @spec validate_required(struct(), [atom()], String.t()) :: :ok | {:error, String.t()}
  def validate_required(struct, required_fields, context \\ "") do
    missing =
      Enum.filter(required_fields, fn field ->
        Map.get(struct, field) == nil
      end)

    case missing do
      [] ->
        :ok

      fields ->
        field_names = Enum.map_join(fields, ", ", &to_string/1)
        context_prefix = if context != "", do: "#{context}: ", else: ""
        {:error, "#{context_prefix}Required field(s) missing: #{field_names}"}
    end
  end

  @doc """
  Validates that a field has the expected type.

  Supported types: :string, :integer, :float, :number, :boolean, :map, :list
  """
  @spec validate_type(any(), atom(), String.t()) :: :ok | {:error, String.t()}
  def validate_type(value, _expected_type, _field_path) when is_nil(value), do: :ok

  def validate_type(value, :string, field_path) do
    if is_binary(value) do
      :ok
    else
      {:error, "#{field_path} must be a string, got: #{inspect(value)}"}
    end
  end

  def validate_type(value, :integer, field_path) do
    if is_integer(value) do
      :ok
    else
      {:error, "#{field_path} must be an integer, got: #{inspect(value)}"}
    end
  end

  def validate_type(value, :float, field_path) do
    if is_float(value) do
      :ok
    else
      {:error, "#{field_path} must be a float, got: #{inspect(value)}"}
    end
  end

  def validate_type(value, :number, field_path) do
    if is_number(value) do
      :ok
    else
      {:error, "#{field_path} must be a number, got: #{inspect(value)}"}
    end
  end

  def validate_type(value, :boolean, field_path) do
    if is_boolean(value) do
      :ok
    else
      {:error, "#{field_path} must be a boolean, got: #{inspect(value)}"}
    end
  end

  def validate_type(value, :map, field_path) do
    if is_map(value) do
      :ok
    else
      {:error, "#{field_path} must be a map, got: #{inspect(value)}"}
    end
  end

  def validate_type(value, :list, field_path) do
    if is_list(value) do
      :ok
    else
      {:error, "#{field_path} must be a list, got: #{inspect(value)}"}
    end
  end

  @doc """
  Validates string format (email, uri, url, etc.).
  """
  @spec validate_format(String.t() | nil, atom(), String.t()) :: :ok | {:error, String.t()}
  def validate_format(nil, _format, _field_path), do: :ok
  def validate_format("", _format, _field_path), do: :ok

  def validate_format(value, :email, field_path) do
    if String.match?(value, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/) do
      :ok
    else
      {:error, "#{field_path} must be a valid email address"}
    end
  end

  def validate_format(value, :uri, field_path) do
    uri = URI.parse(value)

    if uri.scheme != nil do
      :ok
    else
      {:error, "#{field_path} must be a valid URI"}
    end
  end

  def validate_format(value, :url, field_path) do
    uri = URI.parse(value)

    if uri.scheme in ["http", "https"] and uri.host != nil do
      :ok
    else
      {:error, "#{field_path} must be a valid URL"}
    end
  end

  def validate_format(value, :uuid, field_path) do
    if String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) do
      :ok
    else
      {:error, "#{field_path} must be a valid UUID"}
    end
  end

  @doc """
  Validates that a value is one of the allowed enum values.
  """
  @spec validate_enum(any(), [any()], String.t()) :: :ok | {:error, String.t()}
  def validate_enum(nil, _allowed_values, _field_path), do: :ok

  def validate_enum(value, allowed_values, field_path) do
    if value in allowed_values do
      :ok
    else
      allowed = Enum.map_join(allowed_values, ", ", &inspect/1)
      {:error, "#{field_path} must be one of: #{allowed}, got: #{inspect(value)}"}
    end
  end

  @doc """
  Validates that a string matches a pattern.
  """
  @spec validate_pattern(String.t() | nil, Regex.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_pattern(nil, _pattern, _field_path), do: :ok
  def validate_pattern("", _pattern, _field_path), do: :ok

  def validate_pattern(value, pattern, field_path) do
    if String.match?(value, pattern) do
      :ok
    else
      {:error, "#{field_path} does not match the required pattern"}
    end
  end

  @doc """
  Validates all values in a map by calling a validation function on each.
  """
  @spec validate_map_values(
          map() | nil,
          (any(), String.t() -> :ok | {:error, String.t()}),
          String.t()
        ) ::
          :ok | {:error, String.t()}
  def validate_map_values(nil, _validator, _field_path), do: :ok
  def validate_map_values(map, _validator, _field_path) when map == %{}, do: :ok

  def validate_map_values(map, validator, field_path) when is_map(map) do
    results =
      Enum.map(map, fn {key, value} ->
        path = "#{field_path}.#{key}"
        validator.(value, path)
      end)

    combine_results(results)
  end

  @doc """
  Validates all items in a list by calling a validation function on each.
  """
  @spec validate_list_items(
          list() | nil,
          (any(), String.t() -> :ok | {:error, String.t()}),
          String.t()
        ) ::
          :ok | {:error, String.t()}
  def validate_list_items(nil, _validator, _field_path), do: :ok
  def validate_list_items([], _validator, _field_path), do: :ok

  def validate_list_items(list, validator, field_path) when is_list(list) do
    results =
      list
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        path = "#{field_path}[#{index}]"
        validator.(item, path)
      end)

    combine_results(results)
  end

  @doc """
  Combines multiple validation results into a single result.

  If all validations pass, returns :ok.
  If any validation fails, returns the first error.
  """
  @spec combine_results([{:ok | :error, any()}]) :: :ok | {:error, String.t()}
  def combine_results(results) do
    errors =
      results
      |> Enum.filter(fn
        :ok -> false
        {:ok} -> false
        {:error, _} -> true
      end)

    case errors do
      [] -> :ok
      [{:error, msg} | _] -> {:error, msg}
    end
  end

  @doc """
  Validates HTTP status codes.
  """
  @spec validate_status_code(String.t() | integer(), String.t()) :: :ok | {:error, String.t()}
  def validate_status_code(code, field_path) when is_integer(code) do
    validate_status_code(Integer.to_string(code), field_path)
  end

  def validate_status_code("default", _field_path), do: :ok

  def validate_status_code(code, field_path) when is_binary(code) do
    cond do
      String.match?(code, ~r/^[1-5]XX$/) ->
        :ok

      String.match?(code, ~r/^[1-5][0-9][0-9]$/) ->
        status_code = String.to_integer(code)

        if status_code >= 100 and status_code <= 599 do
          :ok
        else
          {:error, "#{field_path} must be a valid HTTP status code (100-599)"}
        end

      true ->
        {:error,
         "#{field_path} must be a valid HTTP status code or pattern (e.g., '200', '2XX', 'default')"}
    end
  end

  @doc """
  Validates that paths start with a forward slash.
  """
  @spec validate_path_format(String.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_path_format(path, field_path) do
    if String.starts_with?(path, "/") do
      :ok
    else
      {:error, "#{field_path} must start with '/', got: #{path}"}
    end
  end

  @doc """
  Validates reference format ($ref).
  """
  @spec validate_reference(String.t() | nil, String.t()) :: :ok | {:error, String.t()}
  def validate_reference(nil, field_path), do: {:error, "#{field_path} $ref is required"}

  def validate_reference(ref, field_path) when is_binary(ref) do
    cond do
      String.starts_with?(ref, "#/") ->
        :ok

      String.contains?(ref, "://") ->
        :ok

      String.contains?(ref, "#") ->
        :ok

      true ->
        {:error, "#{field_path} $ref must be a valid reference (internal or external)"}
    end
  end

  @doc """
  Validates content type format.
  """
  @spec validate_content_type(String.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_content_type(content_type, field_path) do
    # Basic validation for media type format (type/subtype)
    if String.match?(
         content_type,
         ~r/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+.]*$/
       ) or
         content_type == "*/*" or String.match?(content_type, ~r/^[a-zA-Z0-9]+\/\*$/) do
      :ok
    else
      {:error, "#{field_path} must be a valid media type"}
    end
  end
end
