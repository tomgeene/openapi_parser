defmodule OpenapiParser.Spec.V3.Parameter do
  @moduledoc """
  Parameter Object for OpenAPI V3.

  Describes a single operation parameter.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.{Example, MediaType, Reference, Schema}
  alias OpenapiParser.Validation

  @type location :: :query | :header | :path | :cookie

  @type t :: %__MODULE__{
          name: String.t(),
          location: location(),
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
          examples: %{String.t() => Example.t() | Reference.t()} | nil,
          content: %{String.t() => MediaType.t()} | nil
        }

  defstruct [
    :name,
    :location,
    :description,
    :required,
    :deprecated,
    :allow_empty_value,
    :style,
    :explode,
    :allow_reserved,
    :schema,
    :example,
    :examples,
    :content
  ]

  @doc """
  Creates a new Parameter struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, schema} <- parse_schema(data),
         {:ok, examples} <- parse_examples(data),
         {:ok, content} <- parse_content(data) do
      parameter = %__MODULE__{
        name: Map.get(data, :name),
        location: parse_location(data[:in]),
        description: Map.get(data, :description),
        required: Map.get(data, :required, false),
        deprecated: Map.get(data, :deprecated),
        allow_empty_value: Map.get(data, :allowEmptyValue),
        style: Map.get(data, :style),
        explode: Map.get(data, :explode),
        allow_reserved: Map.get(data, :allowReserved),
        schema: schema,
        example: Map.get(data, :example),
        examples: examples,
        content: content
      }

      {:ok, parameter}
    end
  end

  defp parse_location("query"), do: :query
  defp parse_location("header"), do: :header
  defp parse_location("path"), do: :path
  defp parse_location("cookie"), do: :cookie
  defp parse_location(_), do: nil

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

  defp parse_content(%{:content => content}) when is_map(content) do
    result =
      Enum.reduce_while(content, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case MediaType.new(value) do
          {:ok, media_type} -> {:cont, {:ok, Map.put(acc, key, media_type)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_content(_), do: {:ok, nil}

  @doc """
  Validates a Parameter struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = parameter, context \\ "parameter") do
    validations = [
      Validation.validate_required(parameter, [:name, :location], context),
      Validation.validate_type(parameter.name, :string, "#{context}.name"),
      Validation.validate_enum(
        parameter.location,
        [:query, :header, :path, :cookie],
        "#{context}.in"
      ),
      validate_path_parameter(parameter, context),
      validate_schema_or_content(parameter, context),
      validate_schema(parameter.schema, context),
      validate_examples(parameter.examples, context),
      validate_content(parameter.content, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_path_parameter(%{location: :path, required: false}, context) do
    {:error, "#{context}: Path parameter must be required"}
  end

  defp validate_path_parameter(_, _), do: :ok

  defp validate_schema_or_content(%{schema: nil, content: nil}, context) do
    {:error, "#{context}: Either schema or content is required"}
  end

  defp validate_schema_or_content(%{schema: schema, content: content}, context)
       when not is_nil(schema) and not is_nil(content) do
    {:error, "#{context}: schema and content are mutually exclusive"}
  end

  defp validate_schema_or_content(_, _), do: :ok

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

  defp validate_content(nil, _context), do: :ok

  defp validate_content(content, context) when is_map(content) do
    if map_size(content) != 1 do
      {:error, "#{context}.content: must contain exactly one entry"}
    else
      Validation.validate_map_values(
        content,
        fn media_type, path ->
          MediaType.validate(media_type, path)
        end,
        "#{context}.content"
      )
    end
  end
end
