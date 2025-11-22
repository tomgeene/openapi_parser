defmodule OpenapiParser.Spec.V3.ServerVariable do
  @moduledoc """
  Server Variable Object for OpenAPI V3.

  An object representing a Server Variable for server URL template substitution.
  """

  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          enum: [String.t()] | nil,
          default: String.t(),
          description: String.t() | nil
        }

  defstruct [:enum, :default, :description]

  @doc """
  Creates a new ServerVariable struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    variable = %__MODULE__{
      enum: Map.get(data, "enum"),
      default: Map.get(data, "default"),
      description: Map.get(data, "description")
    }

    {:ok, variable}
  end

  @doc """
  Validates a ServerVariable struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = variable, context \\ "serverVariable") do
    validations = [
      Validation.validate_required(variable, [:default], context),
      Validation.validate_type(variable.default, :string, "#{context}.default"),
      Validation.validate_type(variable.description, :string, "#{context}.description"),
      validate_default_in_enum(variable, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_default_in_enum(%{enum: enum, default: default}, context)
       when is_list(enum) and not is_nil(default) do
    if default in enum do
      :ok
    else
      {:error, "#{context}.default must be one of the enum values"}
    end
  end

  defp validate_default_in_enum(_, _), do: :ok
end
