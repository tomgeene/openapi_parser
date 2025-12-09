defmodule OpenapiParser.Spec.V2.Swagger do
  @moduledoc """
  Root Swagger Object for Swagger 2.0.
  This is the root document object for the API specification.
  """

  alias OpenapiParser.Spec.{ExternalDocumentation, Info, Tag}

  alias OpenapiParser.Spec.V2.{
    Parameter,
    PathItem,
    Response,
    SecurityRequirement,
    SecurityScheme,
    Schema
  }

  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          swagger: String.t(),
          info: Info.t(),
          host: String.t() | nil,
          base_path: String.t() | nil,
          schemes: [String.t()] | nil,
          consumes: [String.t()] | nil,
          produces: [String.t()] | nil,
          paths: %{String.t() => PathItem.t()},
          definitions: %{String.t() => Schema.t()} | nil,
          parameters: %{String.t() => Schema.t()} | nil,
          responses: %{String.t() => Schema.t()} | nil,
          security_definitions: %{String.t() => SecurityScheme.t()} | nil,
          security: [SecurityRequirement.t()] | nil,
          tags: [Tag.t()] | nil,
          external_docs: ExternalDocumentation.t() | nil
        }

  defstruct [
    :swagger,
    :info,
    :host,
    :base_path,
    :schemes,
    :consumes,
    :produces,
    :paths,
    :definitions,
    :parameters,
    :responses,
    :security_definitions,
    :security,
    :tags,
    :external_docs
  ]

  @doc """
  Creates a new Swagger struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    with {:ok, info} <- parse_info(data),
         {:ok, paths} <- parse_paths(data),
         {:ok, definitions} <- parse_definitions(data),
         {:ok, parameters} <- parse_parameters(data),
         {:ok, responses} <- parse_responses(data),
         {:ok, security_definitions} <- parse_security_definitions(data),
         {:ok, security} <- parse_security(data),
         {:ok, tags} <- parse_tags(data),
         {:ok, external_docs} <- parse_external_docs(data) do
      swagger = %__MODULE__{
        swagger: Map.get(data, "swagger"),
        info: info,
        host: Map.get(data, "host"),
        base_path: Map.get(data, "basePath"),
        schemes: Map.get(data, "schemes"),
        consumes: Map.get(data, "consumes"),
        produces: Map.get(data, "produces"),
        paths: paths,
        definitions: definitions,
        parameters: parameters,
        responses: responses,
        security_definitions: security_definitions,
        security: security,
        tags: tags,
        external_docs: external_docs
      }

      {:ok, swagger}
    end
  end

  defp parse_info(%{"info" => info_data}) when is_map(info_data) do
    with {:ok, info} <- Info.new(info_data),
         {:ok, license} <- parse_license(info_data) do
      {:ok, %{info | license: license}}
    end
  end

  defp parse_info(_), do: {:error, "info is required"}

  defp parse_license(%{"license" => license_data}) when is_map(license_data) do
    alias OpenapiParser.Spec.V2.License
    License.new(license_data)
  end

  defp parse_license(_), do: {:ok, nil}

  defp parse_paths(%{"paths" => paths}) when is_map(paths) do
    result =
      Enum.reduce_while(paths, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case PathItem.new(value) do
          {:ok, path_item} -> {:cont, {:ok, Map.put(acc, key, path_item)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_paths(_), do: {:error, "paths is required"}

  defp parse_definitions(%{"definitions" => definitions}) when is_map(definitions) do
    result =
      Enum.reduce_while(definitions, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case Schema.new(value) do
          {:ok, schema} -> {:cont, {:ok, Map.put(acc, key, schema)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_definitions(_), do: {:ok, nil}

  defp parse_parameters(%{"parameters" => parameters}) when is_map(parameters) do
    result =
      Enum.reduce_while(parameters, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case Parameter.new(value) do
          {:ok, param} -> {:cont, {:ok, Map.put(acc, key, param)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_parameters(_), do: {:ok, nil}

  defp parse_responses(%{"responses" => responses}) when is_map(responses) do
    result =
      Enum.reduce_while(responses, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case Response.new(value) do
          {:ok, response} -> {:cont, {:ok, Map.put(acc, key, response)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_responses(_), do: {:ok, nil}

  defp parse_security_definitions(%{"securityDefinitions" => sec_defs}) when is_map(sec_defs) do
    result =
      Enum.reduce_while(sec_defs, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case SecurityScheme.new(value) do
          {:ok, scheme} -> {:cont, {:ok, Map.put(acc, key, scheme)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_security_definitions(_), do: {:ok, nil}

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

  defp parse_tags(%{"tags" => tags}) when is_list(tags) do
    result =
      Enum.reduce_while(tags, {:ok, []}, fn tag_data, {:ok, acc} ->
        case Tag.new(tag_data) do
          {:ok, tag} -> {:cont, {:ok, acc ++ [tag]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_tags(_), do: {:ok, nil}

  defp parse_external_docs(%{"externalDocs" => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  @doc """
  Validates a Swagger struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = swagger, context \\ "swagger") do
    validations = [
      Validation.validate_required(swagger, [:swagger, :info, :paths], context),
      Validation.validate_type(swagger.swagger, :string, "#{context}.swagger"),
      validate_info(swagger.info, context),
      validate_paths(swagger.paths, context),
      validate_definitions(swagger.definitions, context),
      validate_parameters(swagger.parameters, context),
      validate_responses(swagger.responses, context),
      validate_security_definitions(swagger.security_definitions, context),
      validate_security(swagger.security, context),
      validate_tags(swagger.tags, context),
      validate_external_docs(swagger.external_docs, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_info(info, context) do
    Info.validate(info, "#{context}.info")
  end

  defp validate_paths(paths, context) when is_map(paths) do
    Validation.validate_map_values(
      paths,
      fn path_item, path ->
        # Extract the path key
        path_key = path |> String.split(".") |> List.last()

        with :ok <- Validation.validate_path_format(path_key, path),
             :ok <- PathItem.validate(path_item, path) do
          :ok
        end
      end,
      "#{context}.paths"
    )
  end

  defp validate_definitions(nil, _context), do: :ok

  defp validate_definitions(definitions, context) when is_map(definitions) do
    Validation.validate_map_values(
      definitions,
      fn schema, path ->
        Schema.validate(schema, path)
      end,
      "#{context}.definitions"
    )
  end

  defp validate_parameters(nil, _context), do: :ok

  defp validate_parameters(parameters, context) when is_map(parameters) do
    Validation.validate_map_values(
      parameters,
      fn parameter, path ->
        Parameter.validate(parameter, path)
      end,
      "#{context}.parameters"
    )
  end

  defp validate_responses(nil, _context), do: :ok

  defp validate_responses(responses, context) when is_map(responses) do
    Validation.validate_map_values(
      responses,
      fn response, path ->
        Response.validate(response, path)
      end,
      "#{context}.responses"
    )
  end

  defp validate_security_definitions(nil, _context), do: :ok

  defp validate_security_definitions(sec_defs, context) when is_map(sec_defs) do
    Validation.validate_map_values(
      sec_defs,
      fn scheme, path ->
        SecurityScheme.validate(scheme, path)
      end,
      "#{context}.securityDefinitions"
    )
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

  defp validate_tags(nil, _context), do: :ok

  defp validate_tags(tags, context) do
    Validation.validate_list_items(
      tags,
      fn tag, path ->
        Tag.validate(tag, path)
      end,
      "#{context}.tags"
    )
  end

  defp validate_external_docs(nil, _context), do: :ok

  defp validate_external_docs(docs, context) do
    ExternalDocumentation.validate(docs, "#{context}.externalDocs")
  end
end
