defmodule OpenapiParser.Spec.Tag do
  @moduledoc """
  Metadata for a single tag.

  Shared across OpenAPI V2, V3.0, and V3.1.
  """

  alias OpenapiParser.Spec.ExternalDocumentation
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          external_docs: ExternalDocumentation.t() | nil
        }

  defstruct [:name, :description, :external_docs]

  @doc """
  Creates a new Tag struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, external_docs} <- parse_external_docs(data) do
      tag = %__MODULE__{
        name: Map.get(data, "name"),
        description: Map.get(data, "description"),
        external_docs: external_docs
      }

      {:ok, tag}
    end
  end

  def new(_data) do
    {:error, "tag must be a map"}
  end

  defp parse_external_docs(%{"externalDocs" => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  @doc """
  Validates a Tag struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = tag, context \\ "tag") do
    validations = [
      Validation.validate_required(tag, [:name], context),
      Validation.validate_type(tag.name, :string, "#{context}.name"),
      Validation.validate_type(tag.description, :string, "#{context}.description"),
      validate_external_docs(tag.external_docs, "#{context}.externalDocs")
    ]

    Validation.combine_results(validations)
  end

  defp validate_external_docs(nil, _context), do: :ok

  defp validate_external_docs(docs, context) do
    ExternalDocumentation.validate(docs, context)
  end
end
