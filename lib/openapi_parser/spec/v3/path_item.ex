defmodule OpenapiParser.Spec.V3.PathItem do
  @moduledoc """
  Path Item Object for OpenAPI V3.

  Describes the operations available on a single path.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.{Operation, Parameter, Reference, Server}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          summary: String.t() | nil,
          description: String.t() | nil,
          get: Operation.t() | nil,
          put: Operation.t() | nil,
          post: Operation.t() | nil,
          delete: Operation.t() | nil,
          options: Operation.t() | nil,
          head: Operation.t() | nil,
          patch: Operation.t() | nil,
          trace: Operation.t() | nil,
          servers: [Server.t()] | nil,
          parameters: [Parameter.t() | Reference.t()] | nil
        }

  defstruct [
    :summary,
    :description,
    :get,
    :put,
    :post,
    :delete,
    :options,
    :head,
    :patch,
    :trace,
    :servers,
    :parameters
  ]

  @doc """
  Creates a new PathItem struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    with {:ok, get} <- parse_operation(data, :get),
         {:ok, put} <- parse_operation(data, :put),
         {:ok, post} <- parse_operation(data, :post),
         {:ok, delete} <- parse_operation(data, :delete),
         {:ok, options} <- parse_operation(data, :options),
         {:ok, head} <- parse_operation(data, :head),
         {:ok, patch} <- parse_operation(data, :patch),
         {:ok, trace} <- parse_operation(data, :trace),
         {:ok, servers} <- parse_servers(data),
         {:ok, parameters} <- parse_parameters(data) do
      path_item = %__MODULE__{
        summary: Map.get(data, :summary),
        description: Map.get(data, :description),
        get: get,
        put: put,
        post: post,
        delete: delete,
        options: options,
        head: head,
        patch: patch,
        trace: trace,
        servers: servers,
        parameters: parameters
      }

      {:ok, path_item}
    end
  end

  defp parse_operation(data, method) do
    case Map.get(data, method) do
      nil -> {:ok, nil}
      op_data when is_map(op_data) -> Operation.new(op_data)
    end
  end

  defp parse_servers(%{:servers => servers}) when is_list(servers) do
    result =
      Enum.reduce_while(servers, {:ok, []}, fn server_data, {:ok, acc} ->
        case Server.new(server_data) do
          {:ok, server} -> {:cont, {:ok, acc ++ [server]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_servers(_), do: {:ok, nil}

  defp parse_parameters(%{:parameters => params}) when is_list(params) do
    result =
      Enum.reduce_while(params, {:ok, []}, fn param_data, {:ok, acc} ->
        result =
          if Map.has_key?(param_data, :"$ref") do
            Reference.new(param_data)
          else
            Parameter.new(param_data)
          end

        case result do
          {:ok, param} -> {:cont, {:ok, acc ++ [param]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_parameters(_), do: {:ok, nil}

  @doc """
  Validates a PathItem struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = path_item, context \\ "pathItem") do
    validations = [
      validate_operation(path_item.get, "#{context}.get"),
      validate_operation(path_item.put, "#{context}.put"),
      validate_operation(path_item.post, "#{context}.post"),
      validate_operation(path_item.delete, "#{context}.delete"),
      validate_operation(path_item.options, "#{context}.options"),
      validate_operation(path_item.head, "#{context}.head"),
      validate_operation(path_item.patch, "#{context}.patch"),
      validate_operation(path_item.trace, "#{context}.trace"),
      validate_servers(path_item.servers, context),
      validate_parameters(path_item.parameters, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_operation(nil, _context), do: :ok

  defp validate_operation(operation, context) do
    Operation.validate(operation, context)
  end

  defp validate_servers(nil, _context), do: :ok

  defp validate_servers(servers, context) do
    Validation.validate_list_items(
      servers,
      fn server, path ->
        Server.validate(server, path)
      end,
      "#{context}.servers"
    )
  end

  defp validate_parameters(nil, _context), do: :ok

  defp validate_parameters(params, context) do
    Validation.validate_list_items(
      params,
      fn param, path ->
        case param do
          %Reference{} = ref -> Reference.validate(ref, path)
          %Parameter{} = p -> Parameter.validate(p, path)
        end
      end,
      "#{context}.parameters"
    )
  end
end
