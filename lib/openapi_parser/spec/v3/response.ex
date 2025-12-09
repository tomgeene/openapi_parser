defmodule OpenapiParser.Spec.V3.Response do
  @moduledoc """
  Response Object for OpenAPI V3.

  Describes a single response from an API Operation.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.V3.{Header, Link, MediaType, Reference}
  alias OpenapiParser.Validation

  @type t :: %__MODULE__{
          description: String.t(),
          headers: %{String.t() => Header.t() | Reference.t()} | nil,
          content: %{String.t() => MediaType.t()} | nil,
          links: %{String.t() => Link.t() | Reference.t()} | nil
        }

  defstruct [:description, :headers, :content, :links]

  @doc """
  Creates a new Response struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    with {:ok, headers} <- parse_headers(data),
         {:ok, content} <- parse_content(data),
         {:ok, links} <- parse_links(data) do
      response = %__MODULE__{
        description: Map.get(data, :description),
        headers: headers,
        content: content,
        links: links
      }

      {:ok, response}
    end
  end

  defp parse_headers(%{:headers => headers}) when is_map(headers) do
    result =
      Enum.reduce_while(headers, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, :"$ref") do
            Reference.new(value)
          else
            Header.new(value)
          end

        case result do
          {:ok, header} -> {:cont, {:ok, Map.put(acc, key, header)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_headers(_), do: {:ok, nil}

  defp parse_content(%{:content => content}) when is_map(content) do
    result =
      Enum.reduce_while(content, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case MediaType.new(value) do
          {:ok, media_type} -> {:cont, {:ok, Map.put(acc, key, media_type)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_content(_), do: {:ok, nil}

  defp parse_links(%{:links => links}) when is_map(links) do
    result =
      Enum.reduce_while(links, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        result =
          if Map.has_key?(value, :"$ref") do
            Reference.new(value)
          else
            Link.new(value)
          end

        case result do
          {:ok, link} -> {:cont, {:ok, Map.put(acc, key, link)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_links(_), do: {:ok, nil}

  @doc """
  Validates a Response struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = response, context \\ "response") do
    validations = [
      Validation.validate_required(response, [:description], context),
      Validation.validate_type(response.description, :string, "#{context}.description"),
      validate_headers(response.headers, context),
      validate_content(response.content, context),
      validate_links(response.links, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_headers(nil, _context), do: :ok

  defp validate_headers(headers, context) when is_map(headers) do
    Validation.validate_map_values(
      headers,
      fn header, path ->
        case header do
          %Reference{} = ref -> Reference.validate(ref, path)
          %Header{} = h -> Header.validate(h, path)
        end
      end,
      "#{context}.headers"
    )
  end

  defp validate_content(nil, _context), do: :ok

  defp validate_content(content, context) when is_map(content) do
    Validation.validate_map_values(
      content,
      fn media_type, path ->
        MediaType.validate(media_type, path)
      end,
      "#{context}.content"
    )
  end

  defp validate_links(nil, _context), do: :ok

  defp validate_links(links, context) when is_map(links) do
    Validation.validate_map_values(
      links,
      fn link, path ->
        case link do
          %Reference{} = ref -> Reference.validate(ref, path)
          %Link{} = l -> Link.validate(l, path)
        end
      end,
      "#{context}.links"
    )
  end
end
