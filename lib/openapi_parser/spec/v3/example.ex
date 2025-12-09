defmodule OpenapiParser.Spec.V3.Example do
  @moduledoc """
  Example Object for OpenAPI V3.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          summary: String.t() | nil,
          description: String.t() | nil,
          value: any() | nil,
          external_value: String.t() | nil
        }

  defstruct [:summary, :description, :value, :external_value]

  @doc """
  Creates a new Example struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    example = %__MODULE__{
      summary: Map.get(data, :summary),
      description: Map.get(data, :description),
      value: Map.get(data, :value),
      external_value: Map.get(data, :externalValue)
    }

    {:ok, example}
  end

  def new(_data) do
    {:error, "example must be a map"}
  end

  @doc """
  Validates an Example struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = example, context \\ "example") do
    validations = [
      Validation.validate_type(example.summary, :string, "#{context}.summary"),
      Validation.validate_type(example.description, :string, "#{context}.description"),
      Validation.validate_type(example.external_value, :string, "#{context}.externalValue"),
      Validation.validate_format(example.external_value, :url, "#{context}.externalValue"),
      validate_mutual_exclusion(example, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_mutual_exclusion(%{value: value, external_value: external_value}, context)
       when not is_nil(value) and not is_nil(external_value) do
    {:error, "#{context}: value and externalValue are mutually exclusive"}
  end

  defp validate_mutual_exclusion(_, _), do: :ok
end
