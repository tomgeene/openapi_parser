defmodule OpenapiParser.Spec.V3.MediaType do
  @moduledoc """
  Media Type Object for OpenAPI V3.

  Provides schema and examples for the media type identified by its key.
  """

  alias OpenapiParser.Spec.V3.{Encoding, Example, Reference, Schema}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          schema: Schema.t() | Reference.t() | nil,
          example: any() | nil,
          examples: %{String.t() => Example.t() | Reference.t()} | nil,
          encoding: %{String.t() => Encoding.t()} | nil
        }

  defstruct [:schema, :example, :examples, :encoding]

  @doc """
  Creates a new MediaType struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, schema} <- parse_schema(data),
         {:ok, examples} <- parse_examples(data),
         {:ok, encoding} <- parse_encoding(data) do
      media_type = %__MODULE__{
        schema: schema,
        example: Map.get(data, "example"),
        examples: examples,
        encoding: encoding
      }

      {:ok, media_type}
    end
  end

  defp parse_schema(%{"schema" => schema_data}) when is_map(schema_data) do
    Schema.new(schema_data)
  end

  defp parse_schema(_), do: {:ok, nil}

  defp parse_examples(%{"examples" => examples}) when is_map(examples) do
    result =
      Enum.reduce_while(examples, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, "$ref") do
            Reference.new(value)
          else
            Example.new(value)
          end

        case result do
          {:ok, example} -> {:cont, {:ok, Map.put(acc, key, example)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_examples(_), do: {:ok, nil}

  defp parse_encoding(%{"encoding" => encoding}) when is_map(encoding) do
    result =
      Enum.reduce_while(encoding, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case Encoding.new(value) do
          {:ok, enc} -> {:cont, {:ok, Map.put(acc, key, enc)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_encoding(_), do: {:ok, nil}

  @doc """
  Validates a MediaType struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = media_type, context \\ "mediaType") do
    validations = [
      validate_schema(media_type.schema, context),
      validate_examples(media_type.examples, context),
      validate_encoding(media_type.encoding, context),
      validate_example_mutual_exclusion(media_type, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_schema(nil, _context), do: :ok

  defp validate_schema(schema, context) do
    Schema.validate(schema, "#{context}.schema")
  end

  defp validate_examples(nil, _context), do: :ok

  defp validate_examples(examples, context) when is_map(examples) do
    Validation.validate_map_values(
      examples,
      fn example, path ->
        case example do
          %Reference{} = ref -> Reference.validate(ref, path)
          %Example{} = ex -> Example.validate(ex, path)
        end
      end,
      "#{context}.examples"
    )
  end

  defp validate_encoding(nil, _context), do: :ok

  defp validate_encoding(encoding, context) when is_map(encoding) do
    Validation.validate_map_values(
      encoding,
      fn enc, path ->
        Encoding.validate(enc, path)
      end,
      "#{context}.encoding"
    )
  end

  defp validate_example_mutual_exclusion(%{example: example, examples: examples}, context)
       when not is_nil(example) and not is_nil(examples) do
    {:error, "#{context}: example and examples are mutually exclusive"}
  end

  defp validate_example_mutual_exclusion(_, _), do: :ok
end
