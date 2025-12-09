defmodule OpenapiParser.Spec.V2.PathItem do
  @moduledoc """
  Path Item Object for Swagger 2.0.
  Describes the operations available on a single path.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V2.{Operation, Parameter}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          get: Operation.t() | nil,
          put: Operation.t() | nil,
          post: Operation.t() | nil,
          delete: Operation.t() | nil,
          options: Operation.t() | nil,
          head: Operation.t() | nil,
          patch: Operation.t() | nil,
          parameters: [Parameter.t()] | nil,
          ref: String.t() | nil
        }

  defstruct [:get, :put, :post, :delete, :options, :head, :patch, :parameters, :ref]

  @doc """
  Creates a new PathItem struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    # Handle $ref
    if Map.has_key?(data, :"$ref") do
      {:ok, %__MODULE__{ref: data[:"$ref"]}}
    else
      with {:ok, get} <- parse_operation(data, :get),
           {:ok, put} <- parse_operation(data, :put),
           {:ok, post} <- parse_operation(data, :post),
           {:ok, delete} <- parse_operation(data, :delete),
           {:ok, options} <- parse_operation(data, :options),
           {:ok, head} <- parse_operation(data, :head),
           {:ok, patch} <- parse_operation(data, :patch),
           {:ok, parameters} <- parse_parameters(data) do
        path_item = %__MODULE__{
          get: get,
          put: put,
          post: post,
          delete: delete,
          options: options,
          head: head,
          patch: patch,
          parameters: parameters,
          ref: nil
        }

        {:ok, path_item}
      end
    end
  end

  defp parse_operation(data, method) do
    case Map.get(data, method) do
      nil -> {:ok, nil}
      op_data when is_map(op_data) -> Operation.new(op_data)
    end
  end

  defp parse_parameters(%{:parameters => params}) when is_list(params) do
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

  @doc """
  Validates a PathItem struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(path_item, context \\ "pathItem")

  def validate(%__MODULE__{ref: ref} = _path_item, context) when not is_nil(ref) do
    Validation.validate_reference(ref, "#{context}.$ref")
  end

  def validate(%__MODULE__{} = path_item, context) do
    validations = [
      validate_operation(path_item.get, "#{context}.get"),
      validate_operation(path_item.put, "#{context}.put"),
      validate_operation(path_item.post, "#{context}.post"),
      validate_operation(path_item.delete, "#{context}.delete"),
      validate_operation(path_item.options, "#{context}.options"),
      validate_operation(path_item.head, "#{context}.head"),
      validate_operation(path_item.patch, "#{context}.patch"),
      validate_parameters(path_item.parameters, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_operation(nil, _context), do: :ok

  defp validate_operation(operation, context) do
    Operation.validate(operation, context)
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
end
