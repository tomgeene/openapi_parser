defmodule OpenapiParser.Spec.V2.Items do
  @moduledoc """
  A limited subset of JSON-Schema's items object for array parameters (Swagger 2.0).
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type collection_format :: :csv | :ssv | :tsv | :pipes | :multi

  @type t :: %__MODULE__{
          type: atom(),
          format: String.t() | nil,
          items: t() | nil,
          collection_format: collection_format() | nil,
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
  Creates a new Items struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    with {:ok, items} <- parse_items(data) do
      items_struct = %__MODULE__{
        type: parse_type(Map.get(data, :type)),
        format: Map.get(data, :format),
        items: items,
        collection_format: parse_collection_format(Map.get(data, :collectionFormat)),
        default: Map.get(data, :default),
        maximum: Map.get(data, :maximum),
        exclusive_maximum: Map.get(data, :exclusiveMaximum),
        minimum: Map.get(data, :minimum),
        exclusive_minimum: Map.get(data, :exclusiveMinimum),
        max_length: Map.get(data, :maxLength),
        min_length: Map.get(data, :minLength),
        pattern: Map.get(data, :pattern),
        max_items: Map.get(data, :maxItems),
        min_items: Map.get(data, :minItems),
        unique_items: Map.get(data, :uniqueItems),
        enum: Map.get(data, :enum),
        multiple_of: Map.get(data, :multipleOf)
      }

      {:ok, items_struct}
    end
  end

  defp parse_type(nil), do: nil
  defp parse_type("string"), do: :string
  defp parse_type("number"), do: :number
  defp parse_type("integer"), do: :integer
  defp parse_type("boolean"), do: :boolean
  defp parse_type("array"), do: :array
  defp parse_type(_), do: nil

  defp parse_collection_format(nil), do: nil
  defp parse_collection_format("csv"), do: :csv
  defp parse_collection_format("ssv"), do: :ssv
  defp parse_collection_format("tsv"), do: :tsv
  defp parse_collection_format("pipes"), do: :pipes
  defp parse_collection_format("multi"), do: :multi
  defp parse_collection_format(_), do: nil

  defp parse_items(%{:items => items_data}) when is_map(items_data) do
    new(items_data)
  end

  defp parse_items(_data), do: {:ok, nil}

  @doc """
  Validates an Items struct.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = items) do
    validations = [
      Validation.validate_required(items, [:type], "items"),
      Validation.validate_enum(
        items.type,
        [:string, :number, :integer, :boolean, :array],
        "items.type"
      ),
      Validation.validate_type(items.format, :string, "items.format"),
      validate_nested_items(items.items),
      Validation.validate_enum(
        items.collection_format,
        [:csv, :ssv, :tsv, :pipes, :multi],
        "items.collectionFormat"
      )
    ]

    Validation.combine_results(validations)
  end

  def validate(_), do: {:error, "invalid items struct"}

  defp validate_nested_items(nil), do: :ok

  defp validate_nested_items(nested_items) do
    validate(nested_items)
  end
end
