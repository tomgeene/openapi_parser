defmodule OpenapiParser.Spec.V2.SecurityScheme do
  @moduledoc """
  Security Scheme Object for Swagger 2.0.
  """

  alias OpenapiParser.Validation

  @type scheme_type :: :basic | :apiKey | :oauth2

  @type t :: %__MODULE__{
          type: scheme_type(),
          description: String.t() | nil,
          # For apiKey
          name: String.t() | nil,
          location: atom() | nil,
          # For oauth2
          flow: atom() | nil,
          authorization_url: String.t() | nil,
          token_url: String.t() | nil,
          scopes: %{String.t() => String.t()} | nil
        }

  defstruct [
    :type,
    :description,
    :name,
    :location,
    :flow,
    :authorization_url,
    :token_url,
    :scopes
  ]

  @doc """
  Creates a new SecurityScheme struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    scheme = %__MODULE__{
      type: parse_type(data["type"]),
      description: Map.get(data, "description"),
      name: Map.get(data, "name"),
      location: parse_location(data["in"]),
      flow: parse_flow(data["flow"]),
      authorization_url: Map.get(data, "authorizationUrl"),
      token_url: Map.get(data, "tokenUrl"),
      scopes: Map.get(data, "scopes")
    }

    {:ok, scheme}
  end

  defp parse_type("basic"), do: :basic
  defp parse_type("apiKey"), do: :apiKey
  defp parse_type("oauth2"), do: :oauth2
  defp parse_type(_), do: nil

  defp parse_location("query"), do: :query
  defp parse_location("header"), do: :header
  defp parse_location(_), do: nil

  defp parse_flow("implicit"), do: :implicit
  defp parse_flow("password"), do: :password
  defp parse_flow("application"), do: :application
  defp parse_flow("accessCode"), do: :accessCode
  defp parse_flow(_), do: nil

  @doc """
  Validates a SecurityScheme struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = scheme, context \\ "securityScheme") do
    validations = [
      Validation.validate_required(scheme, [:type], context),
      Validation.validate_enum(scheme.type, [:basic, :apiKey, :oauth2], "#{context}.type"),
      validate_api_key(scheme, context),
      validate_oauth2(scheme, context)
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

  defp validate_oauth2(%{type: :oauth2, flow: nil}, context) do
    {:error, "#{context}: flow is required for oauth2 security scheme"}
  end

  defp validate_oauth2(%{type: :oauth2, flow: flow}, _context)
       when flow in [:implicit, :accessCode] do
    # These flows require authorizationUrl
    :ok
  end

  defp validate_oauth2(%{type: :oauth2, flow: flow}, _context)
       when flow in [:password, :application] do
    # These flows require tokenUrl
    :ok
  end

  defp validate_oauth2(_, _), do: :ok
end
