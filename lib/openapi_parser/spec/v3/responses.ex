defmodule OpenapiParser.Spec.V3.Responses do
  @moduledoc """
  Responses Object for OpenAPI V3.

  A container for the expected responses of an operation.
  """

  alias OpenapiParser.Spec.V3.{Reference, Response}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          responses: %{String.t() => Response.t() | Reference.t()}
        }

  defstruct responses: %{}

  @doc """
  Creates a new Responses struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    result =
      Enum.reduce_while(data, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, "$ref") do
            Reference.new(value)
          else
            Response.new(value)
          end

        case result do
          {:ok, response} -> {:cont, {:ok, Map.put(acc, key, response)}}
          error -> {:halt, error}
        end
      end)

    case result do
      {:ok, responses} -> {:ok, %__MODULE__{responses: responses}}
      error -> error
    end
  end

  @doc """
  Validates a Responses struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = responses, context \\ "responses") do
    validations = [
      validate_has_response(responses, context),
      Validation.validate_map_values(
        responses.responses,
        fn response, path ->
          # Extract the status code from the path
          status_code = path |> String.split(".") |> List.last()

          with :ok <- Validation.validate_status_code(status_code, path),
               :ok <- validate_response(response, path) do
            :ok
          end
        end,
        context
      )
    ]

    Validation.combine_results(validations)
  end

  defp validate_has_response(%{responses: responses}, context) when map_size(responses) == 0 do
    {:error, "#{context}: At least one response is required"}
  end

  defp validate_has_response(_, _), do: :ok

  defp validate_response(%Reference{} = ref, context) do
    Reference.validate(ref, context)
  end

  defp validate_response(%Response{} = response, context) do
    Response.validate(response, context)
  end
end
