defmodule OpenapiParser.Spec.V3.Schema do
  @moduledoc """
  Schema Object for OpenAPI V3.

  This is based on JSON Schema but with some differences.
  V3.0 uses JSON Schema Draft 5, V3.1 uses JSON Schema 2020-12.
  """

  alias OpenapiParser.Spec.{ExternalDocumentation, V3}
  alias OpenapiParser.Validation

  @type schema_type :: :string | :number | :integer | :boolean | :array | :object | nil

  # Using any() for complex recursive types to avoid dialyzer issues
  @type t :: %__MODULE__{
          # Type and format
          type: schema_type() | [schema_type()],
          format: String.t() | nil,
          # String validation
          max_length: integer() | nil,
          min_length: integer() | nil,
          pattern: String.t() | nil,
          # Number validation
          maximum: number() | nil,
          exclusive_maximum: boolean() | number() | nil,
          minimum: number() | nil,
          exclusive_minimum: boolean() | number() | nil,
          multiple_of: number() | nil,
          # Array validation
          items: any() | nil,
          max_items: integer() | nil,
          min_items: integer() | nil,
          unique_items: boolean() | nil,
          # Object validation
          properties: %{String.t() => any()} | nil,
          additional_properties: any() | boolean() | nil,
          required: [String.t()] | nil,
          max_properties: integer() | nil,
          min_properties: integer() | nil,
          # General validation
          enum: [any()] | nil,
          const: any() | nil,
          default: any() | nil,
          # Composition
          all_of: [any()] | nil,
          any_of: [any()] | nil,
          one_of: [any()] | nil,
          not: any() | nil,
          # Metadata
          title: String.t() | nil,
          description: String.t() | nil,
          example: any() | nil,
          examples: [any()] | nil,
          external_docs: ExternalDocumentation.t() | nil,
          deprecated: boolean() | nil,
          # OpenAPI specific
          discriminator: V3.Discriminator.t() | nil,
          read_only: boolean() | nil,
          write_only: boolean() | nil,
          xml: V3.Xml.t() | nil,
          # V3.1 specific
          content_encoding: String.t() | nil,
          content_media_type: String.t() | nil,
          content_schema: any() | nil
        }

  defstruct [
    :type,
    :format,
    :max_length,
    :min_length,
    :pattern,
    :maximum,
    :exclusive_maximum,
    :minimum,
    :exclusive_minimum,
    :multiple_of,
    :items,
    :max_items,
    :min_items,
    :unique_items,
    :properties,
    :additional_properties,
    :required,
    :max_properties,
    :min_properties,
    :enum,
    :const,
    :default,
    :all_of,
    :any_of,
    :one_of,
    :not,
    :title,
    :description,
    :example,
    :examples,
    :external_docs,
    :deprecated,
    :discriminator,
    :read_only,
    :write_only,
    :xml,
    :content_encoding,
    :content_media_type,
    :content_schema
  ]

  @doc """
  Creates a new Schema struct from a map.
  Handles both Schema objects and Reference objects.
  """
  @spec new(map()) :: {:ok, t() | V3.Reference.t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    # Handle $ref
    if Map.has_key?(data, "$ref") do
      V3.Reference.new(data)
    else
      with {:ok, items} <- parse_items(data),
           {:ok, properties} <- parse_properties(data),
           {:ok, additional_properties} <- parse_additional_properties(data),
           {:ok, all_of} <- parse_composition(data, "allOf"),
           {:ok, any_of} <- parse_composition(data, "anyOf"),
           {:ok, one_of} <- parse_composition(data, "oneOf"),
           {:ok, not_schema} <- parse_not(data),
           {:ok, external_docs} <- parse_external_docs(data),
           {:ok, discriminator} <- parse_discriminator(data),
           {:ok, xml} <- parse_xml(data) do
        schema = %__MODULE__{
          type: parse_type(data["type"]),
          format: Map.get(data, "format"),
          max_length: Map.get(data, "maxLength"),
          min_length: Map.get(data, "minLength"),
          pattern: Map.get(data, "pattern"),
          maximum: Map.get(data, "maximum"),
          exclusive_maximum: Map.get(data, "exclusiveMaximum"),
          minimum: Map.get(data, "minimum"),
          exclusive_minimum: Map.get(data, "exclusiveMinimum"),
          multiple_of: Map.get(data, "multipleOf"),
          items: items,
          max_items: Map.get(data, "maxItems"),
          min_items: Map.get(data, "minItems"),
          unique_items: Map.get(data, "uniqueItems"),
          properties: properties,
          additional_properties: additional_properties,
          required: Map.get(data, "required"),
          max_properties: Map.get(data, "maxProperties"),
          min_properties: Map.get(data, "minProperties"),
          enum: Map.get(data, "enum"),
          const: Map.get(data, "const"),
          default: Map.get(data, "default"),
          all_of: all_of,
          any_of: any_of,
          one_of: one_of,
          not: not_schema,
          title: Map.get(data, "title"),
          description: Map.get(data, "description"),
          example: Map.get(data, "example"),
          examples: Map.get(data, "examples"),
          external_docs: external_docs,
          deprecated: Map.get(data, "deprecated"),
          discriminator: discriminator,
          read_only: Map.get(data, "readOnly"),
          write_only: Map.get(data, "writeOnly"),
          xml: xml,
          content_encoding: Map.get(data, "contentEncoding"),
          content_media_type: Map.get(data, "contentMediaType"),
          content_schema: Map.get(data, "contentSchema")
        }

        {:ok, schema}
      end
    end
  end

  defp parse_type(nil), do: nil

  defp parse_type(types) when is_list(types) do
    Enum.map(types, &parse_single_type/1)
  end

  defp parse_type(type), do: parse_single_type(type)

  defp parse_single_type("string"), do: :string
  defp parse_single_type("number"), do: :number
  defp parse_single_type("integer"), do: :integer
  defp parse_single_type("boolean"), do: :boolean
  defp parse_single_type("array"), do: :array
  defp parse_single_type("object"), do: :object
  defp parse_single_type("null"), do: nil
  defp parse_single_type(_), do: nil

  defp parse_items(%{"items" => items_data}) when is_map(items_data) do
    new(items_data)
  end

  defp parse_items(_), do: {:ok, nil}

  defp parse_properties(%{"properties" => props}) when is_map(props) do
    result =
      Enum.reduce_while(props, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case new(value) do
          {:ok, schema} -> {:cont, {:ok, Map.put(acc, key, schema)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_properties(_), do: {:ok, nil}

  defp parse_additional_properties(%{"additionalProperties" => false}), do: {:ok, false}
  defp parse_additional_properties(%{"additionalProperties" => true}), do: {:ok, true}

  defp parse_additional_properties(%{"additionalProperties" => schema_data})
       when is_map(schema_data) do
    new(schema_data)
  end

  defp parse_additional_properties(_), do: {:ok, nil}

  defp parse_composition(data, key) do
    case Map.get(data, key) do
      nil ->
        {:ok, nil}

      schemas when is_list(schemas) ->
        result =
          Enum.reduce_while(schemas, {:ok, []}, fn schema_data, {:ok, acc} ->
            case new(schema_data) do
              {:ok, schema} -> {:cont, {:ok, acc ++ [schema]}}
              error -> {:halt, error}
            end
          end)

        result
    end
  end

  defp parse_not(%{"not" => not_data}) when is_map(not_data) do
    new(not_data)
  end

  defp parse_not(_), do: {:ok, nil}

  defp parse_external_docs(%{"externalDocs" => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  defp parse_discriminator(%{"discriminator" => disc_data}) when is_map(disc_data) do
    V3.Discriminator.new(disc_data)
  end

  defp parse_discriminator(_), do: {:ok, nil}

  defp parse_xml(%{"xml" => xml_data}) when is_map(xml_data) do
    V3.Xml.new(xml_data)
  end

  defp parse_xml(_), do: {:ok, nil}

  @doc """
  Validates a Schema struct.
  """
  @spec validate(t() | V3.Reference.t(), String.t()) :: :ok | {:error, String.t()}
  def validate(schema_or_ref, context \\ "schema")

  def validate(%V3.Reference{} = ref, context) do
    V3.Reference.validate(ref, context)
  end

  def validate(%__MODULE__{} = schema, context) do
    validations = [
      validate_items(schema, context),
      validate_properties(schema.properties, context),
      validate_composition(schema.all_of, "#{context}.allOf"),
      validate_composition(schema.any_of, "#{context}.anyOf"),
      validate_composition(schema.one_of, "#{context}.oneOf"),
      validate_not(schema.not, context),
      validate_external_docs(schema.external_docs, context),
      validate_discriminator(schema.discriminator, context),
      validate_xml(schema.xml, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_items(%{type: :array, items: nil}, context) do
    {:error, "#{context}: items is required when type is array"}
  end

  defp validate_items(%{items: items}, context) when not is_nil(items) do
    validate(items, "#{context}.items")
  end

  defp validate_items(_, _), do: :ok

  defp validate_properties(nil, _context), do: :ok

  defp validate_properties(props, context) when is_map(props) do
    Validation.validate_map_values(
      props,
      fn schema, path ->
        validate(schema, path)
      end,
      "#{context}.properties"
    )
  end

  defp validate_composition(nil, _context), do: :ok

  defp validate_composition(schemas, context) when is_list(schemas) do
    Validation.validate_list_items(
      schemas,
      fn schema, path ->
        validate(schema, path)
      end,
      context
    )
  end

  defp validate_not(nil, _context), do: :ok

  defp validate_not(schema, context) do
    validate(schema, "#{context}.not")
  end

  defp validate_external_docs(nil, _context), do: :ok

  defp validate_external_docs(docs, context) do
    ExternalDocumentation.validate(docs, "#{context}.externalDocs")
  end

  defp validate_discriminator(nil, _context), do: :ok

  defp validate_discriminator(disc, context) do
    V3.Discriminator.validate(disc, "#{context}.discriminator")
  end

  defp validate_xml(nil, _context), do: :ok

  defp validate_xml(xml, context) do
    V3.Xml.validate(xml, "#{context}.xml")
  end
end
