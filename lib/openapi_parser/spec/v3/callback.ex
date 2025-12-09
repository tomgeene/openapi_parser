defmodule OpenapiParser.Spec.V3.Callback do
  @moduledoc """
  Callback Object for OpenAPI V3.

  A map of possible out-of band callbacks related to the parent operation.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.PathItem
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          expressions: %{String.t() => PathItem.t()}
        }

  defstruct expressions: %{}

  @doc """
  Creates a new Callback struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    result =
      Enum.reduce_while(data, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case PathItem.new(value) do
          {:ok, path_item} -> {:cont, {:ok, Map.put(acc, key, path_item)}}
          error -> {:halt, error}
        end
      end)

    case result do
      {:ok, expressions} -> {:ok, %__MODULE__{expressions: expressions}}
      error -> error
    end
  end

  @doc """
  Validates a Callback struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = callback, context \\ "callback") do
    Validation.validate_map_values(
      callback.expressions,
      fn path_item, path ->
        PathItem.validate(path_item, path)
      end,
      context
    )
  end
end
