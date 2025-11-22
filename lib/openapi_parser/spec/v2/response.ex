defmodule OpenapiParser.Spec.V2.Response do
  @moduledoc """
  Response Object for Swagger 2.0.
  """

  alias OpenapiParser.Spec.V2.{Header, Schema}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          description: String.t(),
          schema: Schema.t() | nil,
          headers: %{String.t() => Header.t()} | nil,
          examples: %{String.t() => any()} | nil,
          # Reference
          ref: String.t() | nil
        }

  defstruct [:description, :schema, :headers, :examples, :ref]

  @doc """
  Creates a new Response struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    # Handle $ref
    if Map.has_key?(data, "$ref") do
      {:ok, %__MODULE__{ref: data["$ref"]}}
    else
      with {:ok, schema} <- parse_schema(data),
           {:ok, headers} <- parse_headers(data) do
        response = %__MODULE__{
          description: Map.get(data, "description"),
          schema: schema,
          headers: headers,
          examples: Map.get(data, "examples"),
          ref: nil
        }

        {:ok, response}
      end
    end
  end

  defp parse_schema(%{"schema" => schema_data}) when is_map(schema_data) do
    Schema.new(schema_data)
  end

  defp parse_schema(_), do: {:ok, nil}

  defp parse_headers(%{"headers" => headers}) when is_map(headers) do
    result =
      Enum.reduce_while(headers, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case Header.new(value) do
          {:ok, header} -> {:cont, {:ok, Map.put(acc, key, header)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_headers(_), do: {:ok, nil}

  @doc """
  Validates a Response struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(response, context \\ "response")

  def validate(%__MODULE__{ref: ref} = _response, context) when not is_nil(ref) do
    Validation.validate_reference(ref, "#{context}.$ref")
  end

  def validate(%__MODULE__{} = response, context) do
    validations = [
      Validation.validate_required(response, [:description], context),
      Validation.validate_type(response.description, :string, "#{context}.description"),
      validate_schema(response.schema, context),
      validate_headers(response.headers, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_schema(nil, _context), do: :ok

  defp validate_schema(schema, context) do
    Schema.validate(schema, "#{context}.schema")
  end

  defp validate_headers(nil, _context), do: :ok

  defp validate_headers(headers, context) when is_map(headers) do
    Validation.validate_map_values(
      headers,
      fn header, path ->
        Header.validate(header, path)
      end,
      "#{context}.headers"
    )
  end
end
