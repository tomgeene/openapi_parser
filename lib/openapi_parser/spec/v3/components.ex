defmodule OpenapiParser.Spec.V3.Components do
  @moduledoc """
  Components Object for OpenAPI V3.

  Holds a set of reusable objects for different aspects of the OAS.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          schemas: %{String.t() => V3.Schema.t() | V3.Reference.t()} | nil,
          responses: %{String.t() => V3.Response.t() | V3.Reference.t()} | nil,
          parameters: %{String.t() => V3.Parameter.t() | V3.Reference.t()} | nil,
          examples: %{String.t() => V3.Example.t() | V3.Reference.t()} | nil,
          request_bodies: %{String.t() => V3.RequestBody.t() | V3.Reference.t()} | nil,
          headers: %{String.t() => V3.Header.t() | V3.Reference.t()} | nil,
          security_schemes: %{String.t() => V3.SecurityScheme.t() | V3.Reference.t()} | nil,
          links: %{String.t() => V3.Link.t() | V3.Reference.t()} | nil,
          callbacks: %{String.t() => V3.Callback.t() | V3.Reference.t()} | nil
        }

  defstruct [
    :schemas,
    :responses,
    :parameters,
    :examples,
    :request_bodies,
    :headers,
    :security_schemes,
    :links,
    :callbacks
  ]

  @doc """
  Creates a new Components struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, schemas} <- parse_component(data, :schemas, &V3.Schema.new/1),
         {:ok, responses} <- parse_component(data, :responses, &V3.Response.new/1),
         {:ok, parameters} <- parse_component(data, :parameters, &V3.Parameter.new/1),
         {:ok, examples} <- parse_component(data, :examples, &V3.Example.new/1),
         {:ok, request_bodies} <- parse_component(data, :requestBodies, &V3.RequestBody.new/1),
         {:ok, headers} <- parse_component(data, :headers, &V3.Header.new/1),
         {:ok, security_schemes} <-
           parse_component(data, :securitySchemes, &V3.SecurityScheme.new/1),
         {:ok, links} <- parse_component(data, :links, &V3.Link.new/1),
         {:ok, callbacks} <- parse_component(data, :callbacks, &V3.Callback.new/1) do
      components = %__MODULE__{
        schemas: schemas,
        responses: responses,
        parameters: parameters,
        examples: examples,
        request_bodies: request_bodies,
        headers: headers,
        security_schemes: security_schemes,
        links: links,
        callbacks: callbacks
      }

      {:ok, components}
    end
  end

  defp parse_component(data, key, parser_fn) do
    case Map.get(data, key) do
      nil ->
        {:ok, nil}

      component_map when is_map(component_map) ->
        result =
          Enum.reduce_while(component_map, {:ok, %{}}, fn {name, value}, {:ok, acc} ->
            # Check if it's a reference
            result =
              if Map.has_key?(value, :"$ref") do
                V3.Reference.new(value)
              else
                parser_fn.(value)
              end

            case result do
              {:ok, component} -> {:cont, {:ok, Map.put(acc, name, component)}}
              error -> {:halt, error}
            end
          end)

        result
    end
  end

  @doc """
  Validates a Components struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = components, context \\ "components") do
    validations = [
      validate_schemas(components.schemas, context),
      validate_responses(components.responses, context),
      validate_parameters(components.parameters, context),
      validate_examples(components.examples, context),
      validate_request_bodies(components.request_bodies, context),
      validate_headers(components.headers, context),
      validate_security_schemes(components.security_schemes, context),
      validate_links(components.links, context),
      validate_callbacks(components.callbacks, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_schemas(nil, _context), do: :ok

  defp validate_schemas(schemas, context) when is_map(schemas) do
    Validation.validate_map_values(
      schemas,
      fn schema, path ->
        case schema do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Schema{} = s -> V3.Schema.validate(s, path)
        end
      end,
      "#{context}.schemas"
    )
  end

  defp validate_responses(nil, _context), do: :ok

  defp validate_responses(responses, context) when is_map(responses) do
    Validation.validate_map_values(
      responses,
      fn response, path ->
        case response do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Response{} = r -> V3.Response.validate(r, path)
        end
      end,
      "#{context}.responses"
    )
  end

  defp validate_parameters(nil, _context), do: :ok

  defp validate_parameters(parameters, context) when is_map(parameters) do
    Validation.validate_map_values(
      parameters,
      fn parameter, path ->
        case parameter do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Parameter{} = p -> V3.Parameter.validate(p, path)
        end
      end,
      "#{context}.parameters"
    )
  end

  defp validate_examples(nil, _context), do: :ok

  defp validate_examples(examples, context) when is_map(examples) do
    Validation.validate_map_values(
      examples,
      fn example, path ->
        case example do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Example{} = ex -> V3.Example.validate(ex, path)
        end
      end,
      "#{context}.examples"
    )
  end

  defp validate_request_bodies(nil, _context), do: :ok

  defp validate_request_bodies(request_bodies, context) when is_map(request_bodies) do
    Validation.validate_map_values(
      request_bodies,
      fn body, path ->
        case body do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.RequestBody{} = rb -> V3.RequestBody.validate(rb, path)
        end
      end,
      "#{context}.requestBodies"
    )
  end

  defp validate_headers(nil, _context), do: :ok

  defp validate_headers(headers, context) when is_map(headers) do
    Validation.validate_map_values(
      headers,
      fn header, path ->
        case header do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Header{} = h -> V3.Header.validate(h, path)
        end
      end,
      "#{context}.headers"
    )
  end

  defp validate_security_schemes(nil, _context), do: :ok

  defp validate_security_schemes(schemes, context) when is_map(schemes) do
    Validation.validate_map_values(
      schemes,
      fn scheme, path ->
        case scheme do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.SecurityScheme{} = ss -> V3.SecurityScheme.validate(ss, path)
        end
      end,
      "#{context}.securitySchemes"
    )
  end

  defp validate_links(nil, _context), do: :ok

  defp validate_links(links, context) when is_map(links) do
    Validation.validate_map_values(
      links,
      fn link, path ->
        case link do
          %V3.Reference{} = ref -> V3.Reference.validate(ref, path)
          %V3.Link{} = l -> V3.Link.validate(l, path)
        end
      end,
      "#{context}.links"
    )
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
end
