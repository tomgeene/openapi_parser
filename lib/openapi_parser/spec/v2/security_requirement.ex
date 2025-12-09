defmodule OpenapiParser.Spec.V2.SecurityRequirement do
  @moduledoc """
  Security Requirement Object for Swagger 2.0.

  Lists the required security schemes to execute this operation.
  Maps security scheme names to lists of required scopes.
  """

  alias OpenapiParser.KeyNormalizer

  @type t :: %__MODULE__{
          requirements: %{String.t() => [String.t()]}
        }

  defstruct [:requirements]

  @doc """
  Creates a new SecurityRequirement struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    security = %__MODULE__{
      requirements: data
    }

    {:ok, security}
  end

  def new(_data) do
    {:error, "security requirement must be a map"}
  end

  @doc """
  Validates a SecurityRequirement struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = _security, _context \\ "security") do
    # Basic validation - just ensure it's a map
    # Detailed validation would require checking against security definitions
    :ok
  end
end
