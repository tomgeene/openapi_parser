defmodule OpenapiParser.Spec.V2.License do
  @moduledoc """
  License information for the exposed API (OpenAPI V2/Swagger 2.0).
  """

  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t() | nil
        }

  defstruct [:name, :url]

  @doc """
  Creates a new License struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    license = %__MODULE__{
      name: Map.get(data, "name"),
      url: Map.get(data, "url")
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
      Validation.validate_format(license.url, :url, "#{context}.url")
    ]

    Validation.combine_results(validations)
  end
end
