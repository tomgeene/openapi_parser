defmodule OpenapiParser.Spec.ExternalDocumentation do
  @moduledoc """
  Reference to external documentation.

  Shared across OpenAPI V2, V3.0, and V3.1.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          url: String.t(),
          description: String.t() | nil
        }

  defstruct [:url, :description]

  @doc """
  Creates a new ExternalDocumentation struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    docs = %__MODULE__{
      url: Map.get(data, :url),
      description: Map.get(data, :description)
    }

    {:ok, docs}
  end

  @doc """
  Validates an ExternalDocumentation struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = docs, context \\ "externalDocs") do
    validations = [
      Validation.validate_required(docs, [:url], context),
      Validation.validate_type(docs.url, :string, "#{context}.url"),
      Validation.validate_format(docs.url, :url, "#{context}.url"),
      Validation.validate_type(docs.description, :string, "#{context}.description")
    ]

    Validation.combine_results(validations)
  end
end
