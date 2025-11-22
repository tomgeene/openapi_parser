defmodule OpenapiParser.Spec.Contact do
  @moduledoc """
  Contact information for the exposed API.

  Shared across OpenAPI V2, V3.0, and V3.1.
  """

  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          name: String.t() | nil,
          url: String.t() | nil,
          email: String.t() | nil
        }

  defstruct [:name, :url, :email]

  @doc """
  Creates a new Contact struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    contact = %__MODULE__{
      name: Map.get(data, "name"),
      url: Map.get(data, "url"),
      email: Map.get(data, "email")
    }

    {:ok, contact}
  end

  @doc """
  Validates a Contact struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = contact, context \\ "contact") do
    validations = [
      Validation.validate_type(contact.name, :string, "#{context}.name"),
      Validation.validate_type(contact.url, :string, "#{context}.url"),
      Validation.validate_format(contact.url, :url, "#{context}.url"),
      Validation.validate_type(contact.email, :string, "#{context}.email"),
      Validation.validate_format(contact.email, :email, "#{context}.email")
    ]

    Validation.combine_results(validations)
  end
end
