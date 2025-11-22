defmodule OpenapiParser.Spec.V2.Operation do
  @moduledoc """
  Operation Object for Swagger 2.0.
  Describes a single API operation on a path.
  """

  alias OpenapiParser.Spec.ExternalDocumentation
  alias OpenapiParser.Spec.V2.{Parameter, Responses, SecurityRequirement}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          tags: [String.t()] | nil,
          summary: String.t() | nil,
          description: String.t() | nil,
          external_docs: ExternalDocumentation.t() | nil,
          operation_id: String.t() | nil,
          consumes: [String.t()] | nil,
          produces: [String.t()] | nil,
          parameters: [Parameter.t()] | nil,
          responses: Responses.t(),
          schemes: [String.t()] | nil,
          deprecated: boolean() | nil,
          security: [SecurityRequirement.t()] | nil
        }

  defstruct [
    :tags,
    :summary,
    :description,
    :external_docs,
    :operation_id,
    :consumes,
    :produces,
    :parameters,
    :responses,
    :schemes,
    :deprecated,
    :security
  ]

  @doc """
  Creates a new Operation struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, external_docs} <- parse_external_docs(data),
         {:ok, parameters} <- parse_parameters(data),
         {:ok, responses} <- parse_responses(data),
         {:ok, security} <- parse_security(data) do
      operation = %__MODULE__{
        tags: Map.get(data, "tags"),
        summary: Map.get(data, "summary"),
        description: Map.get(data, "description"),
        external_docs: external_docs,
        operation_id: Map.get(data, "operationId"),
        consumes: Map.get(data, "consumes"),
        produces: Map.get(data, "produces"),
        parameters: parameters,
        responses: responses,
        schemes: Map.get(data, "schemes"),
        deprecated: Map.get(data, "deprecated"),
        security: security
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
        case Parameter.new(param_data) do
          {:ok, param} -> {:cont, {:ok, acc ++ [param]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_parameters(_), do: {:ok, nil}

  defp parse_responses(%{"responses" => responses_data}) when is_map(responses_data) do
    Responses.new(responses_data)
  end

  defp parse_responses(_), do: {:error, "responses is required"}

  defp parse_security(%{"security" => security}) when is_list(security) do
    result =
      Enum.reduce_while(security, {:ok, []}, fn sec_data, {:ok, acc} ->
        case SecurityRequirement.new(sec_data) do
          {:ok, sec} -> {:cont, {:ok, acc ++ [sec]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_security(_), do: {:ok, nil}

  @doc """
  Validates an Operation struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = operation, context \\ "operation") do
    validations = [
      Validation.validate_required(operation, [:responses], context),
      validate_external_docs(operation.external_docs, context),
      validate_parameters(operation.parameters, context),
      validate_responses(operation.responses, context),
      validate_security(operation.security, context)
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
        Parameter.validate(param, path)
      end,
      "#{context}.parameters"
    )
  end

  defp validate_responses(responses, context) do
    Responses.validate(responses, "#{context}.responses")
  end

  defp validate_security(nil, _context), do: :ok

  defp validate_security(security, context) do
    Validation.validate_list_items(
      security,
      fn sec, path ->
        SecurityRequirement.validate(sec, path)
      end,
      "#{context}.security"
    )
  end
end
