defmodule OpenapiParser.Spec.V2.Schema do
  @moduledoc """
  Schema Object for Swagger 2.0 (JSON Schema subset).
  """

  alias OpenapiParser.Spec.ExternalDocumentation
  alias OpenapiParser.Spec.V2.Xml
  alias OpenapiParser.Validation

  @type schema_type :: :string | :number | :integer | :boolean | :array | :object | :file | nil

  @type t :: %__MODULE__{
          # Type and format
          type: schema_type(),
          format: String.t() | nil,
          # String validation
          max_length: integer() | nil,
          min_length: integer() | nil,
          pattern: String.t() | nil,
          # Number validation
          maximum: number() | nil,
          exclusive_maximum: boolean() | nil,
          minimum: number() | nil,
          exclusive_minimum: boolean() | nil,
          multiple_of: number() | nil,
          # Array validation
          items: t() | nil,
          max_items: integer() | nil,
          min_items: integer() | nil,
          unique_items: boolean() | nil,
          # Object validation
          properties: %{String.t() => t()} | nil,
          additional_properties: t() | boolean() | nil,
          required: [String.t()] | nil,
          max_properties: integer() | nil,
          min_properties: integer() | nil,
          # General validation
          enum: [any()] | nil,
          default: any() | nil,
          # Composition
          all_of: [t()] | nil,
          # Metadata
          title: String.t() | nil,
          description: String.t() | nil,
          example: any() | nil,
          external_docs: ExternalDocumentation.t() | nil,
          # References
          ref: String.t() | nil,
          # Swagger-specific
          discriminator: String.t() | nil,
          read_only: boolean() | nil,
          xml: Xml.t() | nil
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
    :default,
    :all_of,
    :title,
    :description,
    :example,
    :external_docs,
    :ref,
    :discriminator,
    :read_only,
    :xml
  ]

  @doc """
  Creates a new Schema struct from a map.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    # Handle $ref
    if Map.has_key?(data, "$ref") do
      {:ok, %__MODULE__{ref: data["$ref"]}}
    else
      with {:ok, items} <- parse_items(data),
           {:ok, properties} <- parse_properties(data),
           {:ok, additional_properties} <- parse_additional_properties(data),
           {:ok, all_of} <- parse_all_of(data),
           {:ok, external_docs} <- parse_external_docs(data),
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
          default: Map.get(data, "default"),
          all_of: all_of,
          title: Map.get(data, "title"),
          description: Map.get(data, "description"),
          example: Map.get(data, "example"),
          external_docs: external_docs,
          ref: nil,
          discriminator: Map.get(data, "discriminator"),
          read_only: Map.get(data, "readOnly"),
          xml: xml
        }

        {:ok, schema}
      end
    end
  end

  defp parse_type(nil), do: nil
  defp parse_type("string"), do: :string
  defp parse_type("number"), do: :number
  defp parse_type("integer"), do: :integer
  defp parse_type("boolean"), do: :boolean
  defp parse_type("array"), do: :array
  defp parse_type("object"), do: :object
  defp parse_type("file"), do: :file
  defp parse_type(_), do: nil

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

  defp parse_all_of(%{"allOf" => all_of}) when is_list(all_of) do
    result =
      Enum.reduce_while(all_of, {:ok, []}, fn schema_data, {:ok, acc} ->
        case new(schema_data) do
          {:ok, schema} -> {:cont, {:ok, acc ++ [schema]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_all_of(_), do: {:ok, nil}

  defp parse_external_docs(%{"externalDocs" => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  defp parse_xml(%{"xml" => xml_data}) when is_map(xml_data) do
    Xml.new(xml_data)
  end

  defp parse_xml(_), do: {:ok, nil}

  @doc """
  Validates a Schema struct.
  """
  @spec validate(t(), String.t()) :: :ok | {:error, String.t()}
  def validate(schema, context \\ "schema")

  def validate(%__MODULE__{ref: ref} = _schema, context) when not is_nil(ref) do
    Validation.validate_reference(ref, "#{context}.$ref")
  end

  def validate(%__MODULE__{} = schema, context) do
    validations = [
      Validation.validate_enum(
        schema.type,
        [:string, :number, :integer, :boolean, :array, :object, :file, nil],
        "#{context}.type"
      ),
      validate_items(schema, context),
      validate_properties(schema.properties, context),
      validate_all_of(schema.all_of, context),
      validate_external_docs(schema.external_docs, context),
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

  defp validate_all_of(nil, _context), do: :ok

  defp validate_all_of(schemas, context) when is_list(schemas) do
    Validation.validate_list_items(
      schemas,
      fn schema, path ->
        validate(schema, path)
      end,
      "#{context}.allOf"
    )
  end

  defp validate_external_docs(nil, _context), do: :ok

  defp validate_external_docs(docs, context) do
    ExternalDocumentation.validate(docs, "#{context}.externalDocs")
  end

  defp validate_xml(nil, _context), do: :ok

  defp validate_xml(xml, context) do
    Xml.validate(xml, "#{context}.xml")
  end
end
