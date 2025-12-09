defmodule OpenapiParser.Spec.V2.Xml do
  @moduledoc """
  XML Object for Swagger 2.0.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          name: String.t() | nil,
          namespace: String.t() | nil,
          prefix: String.t() | nil,
          attribute: boolean() | nil,
          wrapped: boolean() | nil
        }

  defstruct [:name, :namespace, :prefix, :attribute, :wrapped]

  @doc """
  Creates a new Xml struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    xml = %__MODULE__{
      name: Map.get(data, :name),
      namespace: Map.get(data, :namespace),
      prefix: Map.get(data, :prefix),
      attribute: Map.get(data, :attribute),
      wrapped: Map.get(data, :wrapped)
    }

    {:ok, xml}
  end

  @doc """
  Validates an Xml struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = xml, context \\ "xml") do
    validations = [
      Validation.validate_type(xml.name, :string, "#{context}.name"),
      Validation.validate_type(xml.namespace, :string, "#{context}.namespace"),
      Validation.validate_format(xml.namespace, :uri, "#{context}.namespace"),
      Validation.validate_type(xml.prefix, :string, "#{context}.prefix"),
      Validation.validate_type(xml.attribute, :boolean, "#{context}.attribute"),
      Validation.validate_type(xml.wrapped, :boolean, "#{context}.wrapped")
    ]

    Validation.combine_results(validations)
  end
end
