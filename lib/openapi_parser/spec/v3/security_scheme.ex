defmodule OpenapiParser.Spec.V3.SecurityScheme do
  @moduledoc """
  Security Scheme Object for OpenAPI V3.

  Defines a security scheme that can be used by the operations.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.OAuthFlows
  alias OpenapiParser.Validation

  @type scheme_type :: :apiKey | :http | :mutualTLS | :oauth2 | :openIdConnect

  @type t :: %__MODULE__{
          type: scheme_type(),
          description: String.t() | nil,
          # For apiKey
          name: String.t() | nil,
          location: atom() | nil,
          # For http
          scheme: String.t() | nil,
          bearer_format: String.t() | nil,
          # For oauth2
          flows: OAuthFlows.t() | nil,
          # For openIdConnect
          open_id_connect_url: String.t() | nil
        }

  defstruct [
    :type,
    :description,
    :name,
    :location,
    :scheme,
    :bearer_format,
    :flows,
    :open_id_connect_url
  ]

  @doc """
  Creates a new SecurityScheme struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, flows} <- parse_flows(data) do
      scheme = %__MODULE__{
        type: parse_type(data[:type]),
        description: Map.get(data, :description),
        name: Map.get(data, :name),
        location: parse_location(data[:in]),
        scheme: Map.get(data, :scheme),
        bearer_format: Map.get(data, :bearerFormat),
        flows: flows,
        open_id_connect_url: Map.get(data, :openIdConnectUrl)
      }

      {:ok, scheme}
    end
  end

  defp parse_type("apiKey"), do: :apiKey
  defp parse_type("http"), do: :http
  defp parse_type("mutualTLS"), do: :mutualTLS
  defp parse_type("oauth2"), do: :oauth2
  defp parse_type("openIdConnect"), do: :openIdConnect
  defp parse_type(_), do: nil

  defp parse_location("query"), do: :query
  defp parse_location("header"), do: :header
  defp parse_location("cookie"), do: :cookie
  defp parse_location(_), do: nil

  defp parse_flows(%{:flows => flows_data}) when is_map(flows_data) do
    OAuthFlows.new(flows_data)
  end

  defp parse_flows(_), do: {:ok, nil}

  @doc """
  Validates a SecurityScheme struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = scheme, context \\ "securityScheme") do
    validations = [
      Validation.validate_required(scheme, [:type], context),
      Validation.validate_enum(
        scheme.type,
        [:apiKey, :http, :mutualTLS, :oauth2, :openIdConnect],
        "#{context}.type"
      ),
      validate_api_key(scheme, context),
      validate_http(scheme, context),
      validate_oauth2(scheme, context),
      validate_open_id_connect(scheme, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_api_key(%{type: :apiKey, name: nil}, context) do
    {:error, "#{context}: name is required for apiKey security scheme"}
  end

  defp validate_api_key(%{type: :apiKey, location: nil}, context) do
    {:error, "#{context}: in (location) is required for apiKey security scheme"}
  end

  defp validate_api_key(_, _), do: :ok

  defp validate_http(%{type: :http, scheme: nil}, context) do
    {:error, "#{context}: scheme is required for http security scheme"}
  end

  defp validate_http(_, _), do: :ok

  defp validate_oauth2(%{type: :oauth2, flows: nil}, context) do
    {:error, "#{context}: flows is required for oauth2 security scheme"}
  end

  defp validate_oauth2(%{type: :oauth2, flows: flows}, context) do
    OAuthFlows.validate(flows, "#{context}.flows")
  end

  defp validate_oauth2(_, _), do: :ok

  defp validate_open_id_connect(%{type: :openIdConnect, open_id_connect_url: nil}, context) do
    {:error, "#{context}: openIdConnectUrl is required for openIdConnect security scheme"}
  end

  defp validate_open_id_connect(_, _), do: :ok
end
