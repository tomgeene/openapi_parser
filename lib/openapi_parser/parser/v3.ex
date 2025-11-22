defmodule OpenapiParser.Parser.V3 do
  @moduledoc """
  Parser for OpenAPI 3.x specifications.
  """

  alias OpenapiParser.Spec
  alias OpenapiParser.Spec.{V3, V3_0}

  @doc """
  Parses an OpenAPI 3.x specification from decoded data.
  """
  @spec parse(map(), :v3_0 | :v3_1) :: {:ok, Spec.OpenAPI.t()} | {:error, String.t()}
  def parse(data, :v3_0) when is_map(data) do
    case V3_0.OpenAPI.new(data) do
      {:ok, openapi} ->
        spec = Spec.OpenAPI.new(:v3_0, openapi)
        {:ok, spec}

      {:error, _} = error ->
        error
    end
  end

  def parse(data, :v3_1) when is_map(data) do
    case V3.OpenAPI.new(data) do
      {:ok, openapi} ->
        spec = Spec.OpenAPI.new(:v3_1, openapi)
        {:ok, spec}

      {:error, _} = error ->
        error
    end
  end
end
