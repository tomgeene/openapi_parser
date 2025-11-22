defmodule OpenapiParser.Spec.V3.Link do
  @moduledoc """
  Link Object for OpenAPI V3.

  Represents a possible design-time link for a response.
  """

  alias OpenapiParser.Spec.V3.Server
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          operation_ref: String.t() | nil,
          operation_id: String.t() | nil,
          parameters: %{String.t() => any()} | nil,
          request_body: any() | nil,
          description: String.t() | nil,
          server: Server.t() | nil
        }

  defstruct [:operation_ref, :operation_id, :parameters, :request_body, :description, :server]

  @doc """
  Creates a new Link struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, server} <- parse_server(data) do
      link = %__MODULE__{
        operation_ref: Map.get(data, "operationRef"),
        operation_id: Map.get(data, "operationId"),
        parameters: Map.get(data, "parameters"),
        request_body: Map.get(data, "requestBody"),
        description: Map.get(data, "description"),
        server: server
      }

      {:ok, link}
    end
  end

  defp parse_server(%{"server" => server_data}) when is_map(server_data) do
    Server.new(server_data)
  end

  defp parse_server(_), do: {:ok, nil}

  @doc """
  Validates a Link struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = link, context \\ "link") do
    validations = [
      validate_operation_identifier(link, context),
      Validation.validate_type(link.description, :string, "#{context}.description"),
      validate_server(link.server, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_operation_identifier(%{operation_ref: nil, operation_id: nil}, context) do
    {:error, "#{context}: Either operationRef or operationId is required"}
  end

  defp validate_operation_identifier(%{operation_ref: ref, operation_id: id}, context)
       when not is_nil(ref) and not is_nil(id) do
    {:error, "#{context}: operationRef and operationId are mutually exclusive"}
  end

  defp validate_operation_identifier(_, _), do: :ok

  defp validate_server(nil, _context), do: :ok

  defp validate_server(server, context) do
    Server.validate(server, "#{context}.server")
  end
end
