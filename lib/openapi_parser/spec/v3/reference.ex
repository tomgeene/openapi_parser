defmodule OpenapiParser.Spec.V3.Reference do
  @moduledoc """
  Reference Object for OpenAPI V3.

  A simple object to allow referencing other components in the specification.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          ref: String.t(),
          summary: String.t() | nil,
          description: String.t() | nil
        }

  defstruct [:ref, :summary, :description]

  @doc """
  Creates a new Reference struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    reference = %__MODULE__{
      ref: Map.get(data, :"$ref"),
      summary: Map.get(data, :summary),
      description: Map.get(data, :description)
    }

    {:ok, reference}
  end

  def new(_data) do
    {:error, "reference must be a map"}
  end

  @doc """
  Validates a Reference struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = reference, context \\ "reference") do
    validations = [
      Validation.validate_reference(reference.ref, context),
      Validation.validate_type(reference.summary, :string, "#{context}.summary"),
      Validation.validate_type(reference.description, :string, "#{context}.description")
    ]

    Validation.combine_results(validations)
  end
end
