defmodule OpenapiParser.Spec.Info do
  @moduledoc """
  Metadata about the API.

  Shared across OpenAPI V2, V3.0, and V3.1.
  Note: License object varies between versions, so it's handled separately.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.Contact
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          title: String.t(),
          version: String.t(),
          summary: String.t() | nil,
          description: String.t() | nil,
          terms_of_service: String.t() | nil,
          contact: Contact.t() | nil,
          license: any() | nil
        }

  defstruct [:title, :version, :summary, :description, :terms_of_service, :contact, :license]

  @doc """
  Creates a new Info struct from a map.

  Note: License is handled by version-specific parsers.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, contact} <- parse_contact(data) do
      info = %__MODULE__{
        title: Map.get(data, :title),
        version: Map.get(data, :version),
        summary: Map.get(data, :summary),
        description: Map.get(data, :description),
        terms_of_service: Map.get(data, :termsOfService),
        contact: contact,
        license: nil
      }

      {:ok, info}
    end
  end

  defp parse_contact(%{:contact => contact_data}) when is_map(contact_data) do
    Contact.new(contact_data)
  end

  defp parse_contact(_), do: {:ok, nil}

  @doc """
  Validates an Info struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = info, context \\ "info") do
    validations = [
      Validation.validate_required(info, [:title, :version], context),
      Validation.validate_type(info.title, :string, "#{context}.title"),
      Validation.validate_type(info.version, :string, "#{context}.version"),
      Validation.validate_type(info.summary, :string, "#{context}.summary"),
      Validation.validate_type(info.description, :string, "#{context}.description"),
      Validation.validate_type(info.terms_of_service, :string, "#{context}.termsOfService"),
      validate_contact(info.contact, "#{context}.contact")
    ]

    Validation.combine_results(validations)
  end

  defp validate_contact(nil, _context), do: :ok

  defp validate_contact(contact, context) do
    Contact.validate(contact, context)
  end
end
