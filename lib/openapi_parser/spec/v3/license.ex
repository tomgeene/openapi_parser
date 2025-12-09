defmodule OpenapiParser.Spec.V3.License do
  @moduledoc """
  License information for the exposed API (OpenAPI V3.0 and V3.1).

  V3.1 adds the optional `identifier` field for SPDX license identifiers.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t() | nil,
          identifier: String.t() | nil
        }

  defstruct [:name, :url, :identifier]

  @doc """
  Creates a new License struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    license = %__MODULE__{
      name: Map.get(data, :name),
      url: Map.get(data, :url),
      identifier: Map.get(data, :identifier)
    }

    {:ok, license}
  end

  @doc """
  Validates a License struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = license, context \\ "license") do
    validations = [
      Validation.validate_required(license, [:name], context),
      Validation.validate_type(license.name, :string, "#{context}.name"),
      Validation.validate_type(license.url, :string, "#{context}.url"),
      Validation.validate_format(license.url, :url, "#{context}.url"),
      Validation.validate_type(license.identifier, :string, "#{context}.identifier")
    ]

    Validation.combine_results(validations)
  end
end
