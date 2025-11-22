defmodule OpenapiParser.Parser.V2 do
  @moduledoc """
  Parser for Swagger 2.0 specifications.
  """

  alias OpenapiParser.Spec
  alias OpenapiParser.Spec.V2

  @doc """
  Parses a Swagger 2.0 specification from decoded data.
  """
  @spec parse(map()) :: {:ok, Spec.OpenAPI.t()} | {:error, String.t()}
  def parse(data) when is_map(data) do
    case V2.Swagger.new(data) do
      {:ok, swagger} ->
        spec = Spec.OpenAPI.new(:v2, swagger)
        {:ok, spec}

      {:error, _} = error ->
        error
    end
  end
end
