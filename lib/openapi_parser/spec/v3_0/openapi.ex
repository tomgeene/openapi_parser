defmodule OpenapiParser.Spec.V3_0.OpenAPI do
  @moduledoc """
  OpenAPI 3.0 specific wrapper.

  This is essentially the same as V3.OpenAPI but can enforce V3.0-specific
  validation rules if needed (e.g., exclusive_maximum as boolean instead of number).

  For now, it simply delegates to V3.OpenAPI since the structures are the same.
  """

  alias OpenapiParser.Spec.V3

  @type t :: V3.OpenAPI.t()

  defdelegate new(data), to: V3.OpenAPI
  defdelegate validate(openapi, context \\ "openapi"), to: V3.OpenAPI
end
