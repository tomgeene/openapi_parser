defmodule OpenapiParser.Spec.V3.Discriminator do
  @moduledoc """
  Discriminator Object for OpenAPI V3.

  When request bodies or response payloads may be one of a number of different schemas,
  a discriminator object can be used to aid in serialization, deserialization, and validation.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          property_name: String.t(),
          mapping: %{String.t() => String.t()} | nil
        }

  defstruct [:property_name, :mapping]

  @doc """
  Creates a new Discriminator struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    discriminator = %__MODULE__{
      property_name: Map.get(data, :propertyName),
      mapping: Map.get(data, :mapping)
    }

    {:ok, discriminator}
  end

  @doc """
  Validates a Discriminator struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = discriminator, context \\ "discriminator") do
    validations = [
      Validation.validate_required(discriminator, [:property_name], context),
      Validation.validate_type(discriminator.property_name, :string, "#{context}.propertyName"),
      Validation.validate_type(discriminator.mapping, :map, "#{context}.mapping")
    ]

    Validation.combine_results(validations)
  end
end
