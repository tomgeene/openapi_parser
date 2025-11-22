defmodule OpenapiParser.Spec.V2.Header do
  @moduledoc """
  Header Object for Swagger 2.0.
  """

  alias OpenapiParser.Spec.V2.Schema
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          description: String.t() | nil,
          type: atom(),
          format: String.t() | nil,
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
          multiple_of: number() | nil
        }

  defstruct [
    :description,
    :type,
    :format,
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
    :multiple_of
  ]

  @doc """
  Creates a new Header struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, items} <- parse_items(data) do
      header = %__MODULE__{
        description: Map.get(data, "description"),
        type: parse_type(data["type"]),
        format: Map.get(data, "format"),
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
        multiple_of: Map.get(data, "multipleOf")
      }

      {:ok, header}
    end
  end

  defp parse_type(nil), do: nil
  defp parse_type("string"), do: :string
  defp parse_type("number"), do: :number
  defp parse_type("integer"), do: :integer
  defp parse_type("boolean"), do: :boolean
  defp parse_type("array"), do: :array
  defp parse_type(_), do: nil

  defp parse_items(%{"items" => items_data}) when is_map(items_data) do
    Schema.new(items_data)
  end

  defp parse_items(_), do: {:ok, nil}

  @doc """
  Validates a Header struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = header, context \\ "header") do
    validations = [
      Validation.validate_required(header, [:type], context),
      Validation.validate_enum(
        header.type,
        [:string, :number, :integer, :boolean, :array],
        "#{context}.type"
      ),
      validate_items(header, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_items(%{type: :array, items: nil}, context) do
    {:error, "#{context}: items is required when type is array"}
  end

  defp validate_items(%{items: items}, context) when not is_nil(items) do
    Schema.validate(items, "#{context}.items")
  end

  defp validate_items(_, _), do: :ok
end
