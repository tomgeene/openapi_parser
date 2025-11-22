defmodule OpenapiParser.Spec.V3.Operation do
  @moduledoc """
  Operation Object for OpenAPI V3.

  Describes a single API operation on a path.
  """

  alias OpenapiParser.Spec.{ExternalDocumentation, V3}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          tags: [String.t()] | nil,
          summary: String.t() | nil,
          description: String.t() | nil,
          external_docs: ExternalDocumentation.t() | nil,
          operation_id: String.t() | nil,
          parameters: [V3.Parameter.t() | V3.Reference.t()] | nil,
          request_body: V3.RequestBody.t() | V3.Reference.t() | nil,
          responses: V3.Responses.t(),
          callbacks: %{String.t() => V3.Callback.t() | V3.Reference.t()} | nil,
          deprecated: boolean() | nil,
          security: [V3.SecurityRequirement.t()] | nil,
          servers: [V3.Server.t()] | nil
        }

  defstruct [
    :tags,
    :summary,
    :description,
    :external_docs,
    :operation_id,
    :parameters,
    :request_body,
    :responses,
    :callbacks,
    :deprecated,
    :security,
    :servers
  ]

  @doc """
  Creates a new Operation struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, external_docs} <- parse_external_docs(data),
         {:ok, parameters} <- parse_parameters(data),
         {:ok, request_body} <- parse_request_body(data),
         {:ok, responses} <- parse_responses(data),
         {:ok, callbacks} <- parse_callbacks(data),
         {:ok, security} <- parse_security(data),
         {:ok, servers} <- parse_servers(data) do
      operation = %__MODULE__{
        tags: Map.get(data, "tags"),
        summary: Map.get(data, "summary"),
        description: Map.get(data, "description"),
        external_docs: external_docs,
        operation_id: Map.get(data, "operationId"),
        parameters: parameters,
        request_body: request_body,
        responses: responses,
        callbacks: callbacks,
        deprecated: Map.get(data, "deprecated"),
        security: security,
        servers: servers
      }

      {:ok, operation}
    end
  end

  defp parse_external_docs(%{"externalDocs" => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  defp parse_parameters(%{"parameters" => params}) when is_list(params) do
    result =
      Enum.reduce_while(params, {:ok, []}, fn param_data, {:ok, acc} ->
        result =
          if Map.has_key?(param_data, "$ref") do
            V3.Reference.new(param_data)
          else
            V3.Parameter.new(param_data)
          end

        case result do
          {:ok, param} -> {:cont, {:ok, acc ++ [param]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_parameters(_), do: {:ok, nil}

  defp parse_request_body(%{"requestBody" => body_data}) when is_map(body_data) do
    if Map.has_key?(body_data, "$ref") do
      V3.Reference.new(body_data)
    else
      V3.RequestBody.new(body_data)
    end
  end

  defp parse_request_body(_), do: {:ok, nil}

  defp parse_responses(%{"responses" => responses_data}) when is_map(responses_data) do
    V3.Responses.new(responses_data)
  end

  defp parse_responses(_), do: {:error, "responses is required"}

  defp parse_callbacks(%{"callbacks" => callbacks}) when is_map(callbacks) do
    result =
      Enum.reduce_while(callbacks, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, "$ref") do
            V3.Reference.new(value)
          else
            V3.Callback.new(value)
          end

        case result do
          {:ok, callback} -> {:cont, {:ok, Map.put(acc, key, callback)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_callbacks(_), do: {:ok, nil}

  defp parse_security(%{"security" => security}) when is_list(security) do
    result =
      Enum.reduce_while(security, {:ok, []}, fn sec_data, {:ok, acc} ->
        case V3.SecurityRequirement.new(sec_data) do
          {:ok, sec} -> {:cont, {:ok, acc ++ [sec]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_security(_), do: {:ok, nil}

  defp parse_servers(%{"servers" => servers}) when is_list(servers) do
    result =
      Enum.reduce_while(servers, {:ok, []}, fn server_data, {:ok, acc} ->
        case V3.Server.new(server_data) do
          {:ok, server} -> {:cont, {:ok, acc ++ [server]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_servers(_), do: {:ok, nil}

  @doc """
  Validates an Operation struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = operation, context \\ "operation") do
    validations = [
      Validation.validate_required(operation, [:responses], context),
      validate_external_docs(operation.external_docs, context),
      validate_parameters(operation.parameters, context),
      validate_request_body(operation.request_body, context),
      validate_responses(operation.responses, context),
      validate_callbacks(operation.callbacks, context),
      validate_security(operation.security, context),
      validate_servers(operation.servers, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_external_docs(nil, _context), do: :ok

  defp validate_external_docs(docs, context) do
    ExternalDocumentation.validate(docs, "#{context}.externalDocs")
  end

  defp validate_parameters(nil, _context), do: :ok

  defp validate_parameters(params, context) do
    Validation.validate_list_items(
      params,
      fn param, path ->
        case param do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Parameter{} = p -> V3.Parameter.validate(p, path)
        end
      end,
      "#{context}.parameters"
    )
  end

  defp validate_request_body(nil, _context), do: :ok

  defp validate_request_body(%V3.Reference{} = ref, context) do
    V3.Reference.validate(ref, "#{context}.requestBody")
  end

  defp validate_request_body(%V3.RequestBody{} = body, context) do
    V3.RequestBody.validate(body, "#{context}.requestBody")
  end

  defp validate_responses(responses, context) do
    V3.Responses.validate(responses, "#{context}.responses")
  end

  defp validate_callbacks(nil, _context), do: :ok

  defp validate_callbacks(callbacks, context) when is_map(callbacks) do
    Validation.validate_map_values(
      callbacks,
      fn callback, path ->
        case callback do
          %V3.Reference{} = ref ->
            V3.Reference.validate(ref, path)

          %{__struct__: OpenapiParser.Spec.V3.Callback} = c ->
            OpenapiParser.Spec.V3.Callback.validate(c, path)
        end
      end,
      "#{context}.callbacks"
    )
  end

  defp validate_security(nil, _context), do: :ok

  defp validate_security(security, context) do
    Validation.validate_list_items(
      security,
      fn sec, path ->
        V3.SecurityRequirement.validate(sec, path)
      end,
      "#{context}.security"
    )
  end

  defp validate_servers(nil, _context), do: :ok

  defp validate_servers(servers, context) do
    Validation.validate_list_items(
      servers,
      fn server, path ->
        V3.Server.validate(server, path)
      end,
      "#{context}.servers"
    )
  end
end
