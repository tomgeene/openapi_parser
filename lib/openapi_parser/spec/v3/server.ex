defmodule OpenapiParser.Spec.V3.Server do
  @moduledoc """
  Server Object for OpenAPI V3.

  Represents a Server.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.ServerVariable
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          url: String.t(),
          description: String.t() | nil,
          variables: %{String.t() => ServerVariable.t()} | nil
        }

  defstruct [:url, :description, :variables]

  @doc """
  Creates a new Server struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, variables} <- parse_variables(data) do
      server = %__MODULE__{
        url: Map.get(data, :url),
        description: Map.get(data, :description),
        variables: variables
      }

      {:ok, server}
    end
  end

  defp parse_variables(%{:variables => vars}) when is_map(vars) do
    result =
      Enum.reduce_while(vars, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case ServerVariable.new(value) do
          {:ok, var} -> {:cont, {:ok, Map.put(acc, key, var)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_variables(_), do: {:ok, nil}

  @doc """
  Validates a Server struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = server, context \\ "server") do
    validations = [
      Validation.validate_required(server, [:url], context),
      Validation.validate_type(server.url, :string, "#{context}.url"),
      Validation.validate_type(server.description, :string, "#{context}.description"),
      validate_variables(server.variables, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_variables(nil, _context), do: :ok

  defp validate_variables(vars, context) when is_map(vars) do
    Validation.validate_map_values(
      vars,
      fn var, path ->
        ServerVariable.validate(var, path)
      end,
      "#{context}.variables"
    )
  end
end
