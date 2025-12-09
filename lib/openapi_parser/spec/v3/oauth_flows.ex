defmodule OpenapiParser.Spec.V3.OAuthFlows do
  @moduledoc """
  OAuth Flows Object for OpenAPI V3.

  Allows configuration of the supported OAuth Flows.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.OAuthFlow
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          implicit: OAuthFlow.t() | nil,
          password: OAuthFlow.t() | nil,
          client_credentials: OAuthFlow.t() | nil,
          authorization_code: OAuthFlow.t() | nil
        }

  defstruct [:implicit, :password, :client_credentials, :authorization_code]

  @doc """
  Creates a new OAuthFlows struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, implicit} <- parse_flow(data, :implicit),
         {:ok, password} <- parse_flow(data, :password),
         {:ok, client_credentials} <- parse_flow(data, :clientCredentials),
         {:ok, authorization_code} <- parse_flow(data, :authorizationCode) do
      flows = %__MODULE__{
        implicit: implicit,
        password: password,
        client_credentials: client_credentials,
        authorization_code: authorization_code
      }

      {:ok, flows}
    end
  end

  defp parse_flow(data, key) do
    case Map.get(data, key) do
      nil -> {:ok, nil}
      flow_data when is_map(flow_data) -> OAuthFlow.new(flow_data)
    end
  end

  @doc """
  Validates an OAuthFlows struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = flows, context \\ "oauthFlows") do
    validations = [
      validate_flow(flows.implicit, "#{context}.implicit"),
      validate_flow(flows.password, "#{context}.password"),
      validate_flow(flows.client_credentials, "#{context}.clientCredentials"),
      validate_flow(flows.authorization_code, "#{context}.authorizationCode")
    ]

    Validation.combine_results(validations)
  end

  defp validate_flow(nil, _context), do: :ok

  defp validate_flow(flow, context) do
    OAuthFlow.validate(flow, context)
  end
end
