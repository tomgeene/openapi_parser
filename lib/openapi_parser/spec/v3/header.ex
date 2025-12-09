defmodule OpenapiParser.Spec.V3.Header do
  @moduledoc """
  Header Object for OpenAPI V3.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.{Example, Reference, Schema}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          description: String.t() | nil,
          required: boolean(),
          deprecated: boolean() | nil,
          allow_empty_value: boolean() | nil,
          # Serialization
          style: String.t() | nil,
          explode: boolean() | nil,
          allow_reserved: boolean() | nil,
          schema: Schema.t() | Reference.t() | nil,
          example: any() | nil,
          examples: %{String.t() => Example.t() | Reference.t()} | nil
        }

  defstruct [
    :description,
    :required,
    :deprecated,
    :allow_empty_value,
    :style,
    :explode,
    :allow_reserved,
    :schema,
    :example,
    :examples
  ]

  @doc """
  Creates a new Header struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, schema} <- parse_schema(data),
         {:ok, examples} <- parse_examples(data) do
      header = %__MODULE__{
        description: Map.get(data, :description),
        required: Map.get(data, :required, false),
        deprecated: Map.get(data, :deprecated),
        allow_empty_value: Map.get(data, :allowEmptyValue),
        style: Map.get(data, :style),
        explode: Map.get(data, :explode),
        allow_reserved: Map.get(data, :allowReserved),
        schema: schema,
        example: Map.get(data, :example),
        examples: examples
      }

      {:ok, header}
    end
  end

  defp parse_schema(%{:schema => schema_data}) when is_map(schema_data) do
    Schema.new(schema_data)
  end

  defp parse_schema(_), do: {:ok, nil}

  defp parse_examples(%{:examples => examples}) when is_map(examples) do
    result =
      Enum.reduce_while(examples, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, :"$ref") do
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

  @doc """
  Validates a Header struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = header, context \\ "header") do
    validations = [
      Validation.validate_type(header.description, :string, "#{context}.description"),
      Validation.validate_type(header.required, :boolean, "#{context}.required"),
      Validation.validate_type(header.deprecated, :boolean, "#{context}.deprecated"),
      validate_schema(header.schema, context),
      validate_examples(header.examples, context)
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
end
