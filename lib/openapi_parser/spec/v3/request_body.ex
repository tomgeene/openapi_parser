defmodule OpenapiParser.Spec.V3.RequestBody do
  @moduledoc """
  Request Body Object for OpenAPI V3.

  Describes a single request body.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.MediaType
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          description: String.t() | nil,
          content: %{String.t() => MediaType.t()},
          required: boolean()
        }

  defstruct [:description, :content, :required]

  @doc """
  Creates a new RequestBody struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, content} <- parse_content(data) do
      request_body = %__MODULE__{
        description: Map.get(data, :description),
        content: content,
        required: Map.get(data, :required, false)
      }

      {:ok, request_body}
    end
  end

  defp parse_content(%{:content => content}) when is_map(content) do
    result =
      Enum.reduce_while(content, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case MediaType.new(value) do
          {:ok, media_type} -> {:cont, {:ok, Map.put(acc, key, media_type)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_content(_), do: {:error, "content is required"}

  @doc """
  Validates a RequestBody struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = request_body, context \\ "requestBody") do
    validations = [
      Validation.validate_required(request_body, [:content], context),
      Validation.validate_type(request_body.description, :string, "#{context}.description"),
      Validation.validate_type(request_body.required, :boolean, "#{context}.required"),
      validate_content(request_body.content, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_content(content, context) when is_map(content) do
    Validation.validate_map_values(
      content,
      fn media_type, path ->
        # Validate content type format
        content_type = path |> String.split(".") |> List.last()

        with :ok <- Validation.validate_content_type(content_type, path),
             :ok <- MediaType.validate(media_type, path) do
          :ok
        end
      end,
      "#{context}.content"
    )
  end
end
