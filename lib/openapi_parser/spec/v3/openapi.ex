defmodule OpenapiParser.Spec.V3.OpenAPI do
  @moduledoc """
  Root OpenAPI Object for OpenAPI V3.0 and V3.1.

  This is the root document object for the API specification.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.{ExternalDocumentation, Info, Tag, V3}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          openapi: String.t(),
          info: Info.t(),
          servers: [V3.Server.t()] | nil,
          paths: %{String.t() => V3.PathItem.t() | V3.Reference.t()} | nil,
          components: V3.Components.t() | nil,
          security: [V3.SecurityRequirement.t()] | nil,
          tags: [Tag.t()] | nil,
          external_docs: ExternalDocumentation.t() | nil,
          webhooks: %{String.t() => V3.PathItem.t() | V3.Reference.t()} | nil
        }

  defstruct [
    :openapi,
    :info,
    :servers,
    :paths,
    :components,
    :security,
    :tags,
    :external_docs,
    :webhooks
  ]

  @doc """
  Creates a new OpenAPI struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)

    with {:ok, info} <- parse_info(data),
         {:ok, servers} <- parse_servers(data),
         {:ok, paths} <- parse_paths(data),
         {:ok, webhooks} <- parse_webhooks(data),
         {:ok, components} <- parse_components(data),
         {:ok, security} <- parse_security(data),
         {:ok, tags} <- parse_tags(data),
         {:ok, external_docs} <- parse_external_docs(data) do
      openapi = %__MODULE__{
        openapi: Map.get(data, :openapi),
        info: info,
        servers: servers,
        paths: paths,
        webhooks: webhooks,
        components: components,
        security: security,
        tags: tags,
        external_docs: external_docs
      }

      {:ok, openapi}
    end
  end

  defp parse_info(%{:info => info_data}) when is_map(info_data) do
    # Normalize info_data so we can check for :license
    normalized_info = KeyNormalizer.normalize_shallow(info_data)

    with {:ok, info} <- Info.new(info_data),
         {:ok, license} <- parse_license(normalized_info) do
      {:ok, %{info | license: license}}
    end
  end

  defp parse_info(_), do: {:error, "info is required"}

  defp parse_license(%{:license => license_data}) when is_map(license_data) do
    V3.License.new(license_data)
  end

  defp parse_license(_), do: {:ok, nil}

  defp parse_servers(%{:servers => servers}) when is_list(servers) do
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

  defp parse_paths(%{:paths => paths}) when is_map(paths) do
    result =
      Enum.reduce_while(paths, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, :"$ref") do
            V3.Reference.new(value)
          else
            V3.PathItem.new(value)
          end

        case result do
          {:ok, path_item} -> {:cont, {:ok, Map.put(acc, key, path_item)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_paths(_), do: {:ok, nil}

  defp parse_webhooks(%{:webhooks => webhooks}) when is_map(webhooks) do
    result =
      Enum.reduce_while(webhooks, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, :"$ref") do
            V3.Reference.new(value)
          else
            V3.PathItem.new(value)
          end

        case result do
          {:ok, path_item} -> {:cont, {:ok, Map.put(acc, key, path_item)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_webhooks(_), do: {:ok, nil}

  defp parse_components(%{:components => components_data}) when is_map(components_data) do
    V3.Components.new(components_data)
  end

  defp parse_components(_), do: {:ok, nil}

  defp parse_security(%{:security => security}) when is_list(security) do
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

  defp parse_tags(%{:tags => tags}) when is_list(tags) do
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

  defp parse_external_docs(%{:externalDocs => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  @doc """
  Validates an OpenAPI struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = openapi, context \\ "openapi") do
    validations = [
      Validation.validate_required(openapi, [:openapi, :info], context),
      validate_at_least_one_path_component_webhook(openapi, context),
      Validation.validate_type(openapi.openapi, :string, "#{context}.openapi"),
      validate_info(openapi.info, context),
      validate_servers(openapi.servers, context),
      validate_paths(openapi.paths, context),
      validate_webhooks(openapi.webhooks, context),
      validate_components(openapi.components, context),
      validate_security(openapi.security, context),
      validate_tags(openapi.tags, context),
      validate_external_docs(openapi.external_docs, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_at_least_one_path_component_webhook(openapi, context) do
    version = parse_version(openapi.openapi)

    cond do
      version == "3.1.0" or (is_binary(version) and String.starts_with?(version, "3.1")) ->
        # OpenAPI 3.1: at least one of paths, components, or webhooks must be present
        # Empty maps are considered present
        has_paths = not is_nil(openapi.paths)
        has_components = not is_nil(openapi.components)
        has_webhooks = not is_nil(openapi.webhooks)

        if has_paths or has_components or has_webhooks do
          :ok
        else
          {:error,
           "#{context}: At least one of paths, components, or webhooks must be present (OpenAPI 3.1)"}
        end

      true ->
        # OpenAPI 3.0: paths is required (can be empty map)
        if is_nil(openapi.paths) do
          {:error, "#{context}: paths is required"}
        else
          :ok
        end
    end
  end

  defp parse_version(version_string) when is_binary(version_string) do
    version_string
  end

  defp parse_version(_), do: nil

  defp validate_info(info, context) do
    Info.validate(info, "#{context}.info")
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

  defp validate_paths(nil, _context), do: :ok

  defp validate_paths(paths, context) when is_map(paths) do
    Validation.validate_map_values(
      paths,
      fn path_item, path ->
        # Extract the path key
        path_key = path |> String.split(".") |> List.last()

        with :ok <- Validation.validate_path_format(path_key, path),
             :ok <- validate_path_item(path_item, path) do
          :ok
        end
      end,
      "#{context}.paths"
    )
  end

  defp validate_webhooks(nil, _context), do: :ok

  defp validate_webhooks(webhooks, context) when is_map(webhooks) do
    Validation.validate_map_values(
      webhooks,
      fn path_item, path ->
        validate_path_item(path_item, path)
      end,
      "#{context}.webhooks"
    )
  end

  defp validate_path_item(%V3.Reference{} = ref, context) do
    V3.Reference.validate(ref, context)
  end

  defp validate_path_item(%V3.PathItem{} = path_item, context) do
    V3.PathItem.validate(path_item, context)
  end

  defp validate_components(nil, _context), do: :ok

  defp validate_components(components, context) do
    V3.Components.validate(components, "#{context}.components")
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
