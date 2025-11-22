defmodule OpenapiParser.Spec do
  @moduledoc """
  Top-level module for OpenAPI specification structures.

  Contains the main OpenAPI wrapper that can hold any version of the spec.
  """

  defmodule OpenAPI do
    @moduledoc """
    Top-level OpenAPI spec container that wraps version-specific documents.
    """

    alias OpenapiParser.Spec.{V2, V3, V3_0}

    @type version :: :v2 | :v3_0 | :v3_1
    @type document :: V2.Swagger.t() | V3_0.OpenAPI.t() | V3.OpenAPI.t()

    @type t :: %__MODULE__{
            version: version(),
            document: document()
          }

    defstruct [:version, :document]

    @doc """
    Creates a new OpenAPI spec container.
    """
    @spec new(version(), document()) :: t()
    def new(version, document) do
      %__MODULE__{
        version: version,
        document: document
      }
    end

    @doc """
    Validates the OpenAPI spec.
    """
    @spec validate(t()) :: :ok | {:error, String.t()}
    def validate(%__MODULE__{version: :v2, document: document}) do
      V2.Swagger.validate(document)
    end

    def validate(%__MODULE__{version: :v3_0, document: document}) do
      V3_0.OpenAPI.validate(document)
    end

    def validate(%__MODULE__{version: :v3_1, document: document}) do
      V3.OpenAPI.validate(document)
    end
  end
end
