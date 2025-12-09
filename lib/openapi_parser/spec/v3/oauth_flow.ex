defmodule OpenapiParser.Spec.V3.OAuthFlow do
  @moduledoc """
  OAuth Flow Object for OpenAPI V3.

  Configuration details for a supported OAuth Flow.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          authorization_url: String.t() | nil,
          token_url: String.t() | nil,
          refresh_url: String.t() | nil,
          scopes: %{String.t() => String.t()}
        }

  defstruct [:authorization_url, :token_url, :refresh_url, :scopes]

  @doc """
  Creates a new OAuthFlow struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    flow = %__MODULE__{
      authorization_url: Map.get(data, :authorizationUrl),
      token_url: Map.get(data, :tokenUrl),
      refresh_url: Map.get(data, :refreshUrl),
      scopes: Map.get(data, :scopes, %{})
    }

    {:ok, flow}
  end

  @doc """
  Validates an OAuthFlow struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = flow, context \\ "oauthFlow") do
    validations = [
      Validation.validate_required(flow, [:scopes], context),
      Validation.validate_type(flow.authorization_url, :string, "#{context}.authorizationUrl"),
      Validation.validate_format(flow.authorization_url, :url, "#{context}.authorizationUrl"),
      Validation.validate_type(flow.token_url, :string, "#{context}.tokenUrl"),
      Validation.validate_format(flow.token_url, :url, "#{context}.tokenUrl"),
      Validation.validate_type(flow.refresh_url, :string, "#{context}.refreshUrl"),
      Validation.validate_format(flow.refresh_url, :url, "#{context}.refreshUrl"),
      Validation.validate_type(flow.scopes, :map, "#{context}.scopes")
    ]

    Validation.combine_results(validations)
  end
end
