defmodule OpenapiParser.Spec.V3.Encoding do
  @moduledoc """
  Encoding Object for OpenAPI V3.

  A single encoding definition applied to a single schema property.
  """

  alias OpenapiParser.Spec.V3.Header
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          content_type: String.t() | nil,
          headers: %{String.t() => Header.t() | OpenapiParser.Spec.V3.Reference.t()} | nil,
          style: String.t() | nil,
          explode: boolean() | nil,
          allow_reserved: boolean() | nil
        }

  defstruct [:content_type, :headers, :style, :explode, :allow_reserved]

  @doc """
  Creates a new Encoding struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, headers} <- parse_headers(data) do
      encoding = %__MODULE__{
        content_type: Map.get(data, "contentType"),
        headers: headers,
        style: Map.get(data, "style"),
        explode: Map.get(data, "explode"),
        allow_reserved: Map.get(data, "allowReserved")
      }

      {:ok, encoding}
    end
  end

  defp parse_headers(%{"headers" => headers}) when is_map(headers) do
    result =
      Enum.reduce_while(headers, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        # Headers can be Reference or Header objects
        result =
          if Map.has_key?(value, "$ref") do
            OpenapiParser.Spec.V3.Reference.new(value)
          else
            Header.new(value)
          end

        case result do
          {:ok, header} -> {:cont, {:ok, Map.put(acc, key, header)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_headers(_), do: {:ok, nil}

  @doc """
  Validates an Encoding struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = encoding, context \\ "encoding") do
    validations = [
      Validation.validate_type(encoding.content_type, :string, "#{context}.contentType"),
      validate_headers(encoding.headers, context),
      Validation.validate_type(encoding.style, :string, "#{context}.style"),
      Validation.validate_type(encoding.explode, :boolean, "#{context}.explode"),
      Validation.validate_type(encoding.allow_reserved, :boolean, "#{context}.allowReserved")
    ]

    Validation.combine_results(validations)
  end

  defp validate_headers(nil, _context), do: :ok

  defp validate_headers(headers, context) when is_map(headers) do
    Validation.validate_map_values(
      headers,
      fn header, path ->
        case header do
          %OpenapiParser.Spec.V3.Reference{} = ref ->
            OpenapiParser.Spec.V3.Reference.validate(ref, path)

          %Header{} = h ->
            Header.validate(h, path)
        end
      end,
      "#{context}.headers"
    )
  end
end
