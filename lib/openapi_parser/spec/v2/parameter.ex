defmodule OpenapiParser.Spec.V2.Parameter do
  @moduledoc """
  Parameter Object for Swagger 2.0.
  """

  alias OpenapiParser.Spec.V2.Schema
  alias OpenapiParser.Validation

  @type location :: :query | :header | :path | :formData | :body

  @type t :: %__MODULE__{
          name: String.t(),
          location: location(),
          description: String.t() | nil,
          required: boolean(),
          # For body parameters
          schema: Schema.t() | nil,
          # For non-body parameters
          type: atom() | nil,
          format: String.t() | nil,
          allow_empty_value: boolean() | nil,
          items: Schema.t() | nil,
          collection_format: String.t() | nil,
          default: any() | nil,
          maximum: number() | nil,
          exclusive_maximum: boolean() | nil,
          minimum: number() | nil,
          exclusive_minimum: boolean() | nil,
          max_length: integer() | nil,
          min_length: integer() | nil,
          pattern: String.t() | nil,
          max_items: integer() | nil,
          min_items: integer() | nil,
          unique_items: boolean() | nil,
          enum: [any()] | nil,
          multiple_of: number() | nil,
          # Reference
          ref: String.t() | nil
        }

  defstruct [
    :name,
    :location,
    :description,
    :required,
    :schema,
    :type,
    :format,
    :allow_empty_value,
    :items,
    :collection_format,
    :default,
    :maximum,
    :exclusive_maximum,
    :minimum,
    :exclusive_minimum,
    :max_length,
    :min_length,
    :pattern,
    :max_items,
    :min_items,
    :unique_items,
    :enum,
    :multiple_of,
    :ref
  ]

  @doc """
  Creates a new Parameter struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    # Handle $ref
    if Map.has_key?(data, "$ref") do
      {:ok, %__MODULE__{ref: data["$ref"]}}
    else
      with {:ok, schema} <- parse_schema(data),
           {:ok, items} <- parse_items(data) do
        parameter = %__MODULE__{
          name: Map.get(data, "name"),
          location: parse_location(data["in"]),
          description: Map.get(data, "description"),
          required: Map.get(data, "required", false),
          schema: schema,
          type: parse_type(data["type"]),
          format: Map.get(data, "format"),
          allow_empty_value: Map.get(data, "allowEmptyValue"),
          items: items,
          collection_format: Map.get(data, "collectionFormat"),
          default: Map.get(data, "default"),
          maximum: Map.get(data, "maximum"),
          exclusive_maximum: Map.get(data, "exclusiveMaximum"),
          minimum: Map.get(data, "minimum"),
          exclusive_minimum: Map.get(data, "exclusiveMinimum"),
          max_length: Map.get(data, "maxLength"),
          min_length: Map.get(data, "minLength"),
          pattern: Map.get(data, "pattern"),
          max_items: Map.get(data, "maxItems"),
          min_items: Map.get(data, "minItems"),
          unique_items: Map.get(data, "uniqueItems"),
          enum: Map.get(data, "enum"),
          multiple_of: Map.get(data, "multipleOf"),
          ref: nil
        }

        {:ok, parameter}
      end
    end
  end

  defp parse_location("query"), do: :query
  defp parse_location("header"), do: :header
  defp parse_location("path"), do: :path
  defp parse_location("formData"), do: :formData
  defp parse_location("body"), do: :body
  defp parse_location(_), do: nil

  defp parse_type(nil), do: nil
  defp parse_type("string"), do: :string
  defp parse_type("number"), do: :number
  defp parse_type("integer"), do: :integer
  defp parse_type("boolean"), do: :boolean
  defp parse_type("array"), do: :array
  defp parse_type("file"), do: :file
  defp parse_type(_), do: nil

  defp parse_schema(%{"schema" => schema_data}) when is_map(schema_data) do
    Schema.new(schema_data)
  end

  defp parse_schema(_), do: {:ok, nil}

  defp parse_items(%{"items" => items_data}) when is_map(items_data) do
    Schema.new(items_data)
  end

  defp parse_items(_), do: {:ok, nil}

  @doc """
  Validates a Parameter struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(parameter, context \\ "parameter")

  def validate(%__MODULE__{ref: ref} = _parameter, context) when not is_nil(ref) do
    Validation.validate_reference(ref, "#{context}.$ref")
  end

  def validate(%__MODULE__{} = parameter, context) do
    validations = [
      Validation.validate_required(parameter, [:name, :location], context),
      Validation.validate_type(parameter.name, :string, "#{context}.name"),
      Validation.validate_enum(
        parameter.location,
        [:query, :header, :path, :formData, :body],
        "#{context}.in"
      ),
      validate_path_parameter(parameter, context),
      validate_body_parameter(parameter, context),
      validate_non_body_parameter(parameter, context),
      validate_schema(parameter.schema, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_path_parameter(%{location: :path, required: false}, context) do
    {:error, "#{context}: Path parameter must be required"}
  end

  defp validate_path_parameter(_, _), do: :ok

  defp validate_body_parameter(%{location: :body, schema: nil}, context) do
    {:error, "#{context}: Body parameter must have a schema"}
  end

  defp validate_body_parameter(%{location: :body, type: type}, context) when not is_nil(type) do
    {:error, "#{context}: Body parameter should not have a type field"}
  end

  defp validate_body_parameter(_, _), do: :ok

  defp validate_non_body_parameter(%{location: loc, type: nil}, context)
       when loc in [:query, :header, :path, :formData] do
    {:error, "#{context}: Non-body parameter must have a type"}
  end

  defp validate_non_body_parameter(%{location: loc, schema: schema}, context)
       when loc in [:query, :header, :path, :formData] and not is_nil(schema) do
    {:error, "#{context}: Non-body parameter should not have a schema"}
  end

  defp validate_non_body_parameter(_, _), do: :ok

  defp validate_schema(nil, _context), do: :ok

  defp validate_schema(schema, context) do
    Schema.validate(schema, "#{context}.schema")
  end
end
