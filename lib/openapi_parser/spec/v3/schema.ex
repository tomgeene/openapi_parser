defmodule OpenapiParser.Spec.V3.Schema do
  @moduledoc """
  Schema Object for OpenAPI V3.

  This is based on JSON Schema but with some differences.
  V3.0 uses JSON Schema Draft 5, V3.1 uses JSON Schema 2020-12.
  """

  alias OpenapiParser.KeyNormalizer
  alias OpenapiParser.Spec.{ExternalDocumentation, V3}
  alias OpenapiParser.Validation

  @type schema_type :: :string | :number | :integer | :boolean | :array | :object | :null | nil

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
          prefix_items: [any()] | nil,
          contains: any() | nil,
          min_contains: integer() | nil,
          max_contains: integer() | nil,
          unevaluated_items: any() | boolean() | nil,
          max_items: integer() | nil,
          min_items: integer() | nil,
          unique_items: boolean() | nil,
          # Object validation
          properties: %{String.t() => any()} | nil,
          pattern_properties: %{String.t() => any()} | nil,
          property_names: any() | nil,
          additional_properties: any() | boolean() | nil,
          unevaluated_properties: any() | boolean() | nil,
          required: [String.t()] | nil,
          max_properties: integer() | nil,
          min_properties: integer() | nil,
          dependent_schemas: %{String.t() => any()} | nil,
          # General validation
          enum: [any()] | nil,
          const: any() | nil,
          default: any() | nil,
          # Composition
          all_of: [any()] | nil,
          any_of: [any()] | nil,
          one_of: [any()] | nil,
          not: any() | nil,
          if_schema: any() | nil,
          then_schema: any() | nil,
          else_schema: any() | nil,
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
          content_schema: any() | nil,
          # JSON Schema 2020-12 reference keywords
          defs: %{String.t() => any()} | nil,
          id: String.t() | nil,
          anchor: String.t() | nil,
          dynamic_anchor: String.t() | nil,
          dynamic_ref: String.t() | nil,
          schema_uri: String.t() | nil,
          comment: String.t() | nil,
          # OpenAPI 3.0 compatibility
          nullable: boolean() | nil
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
    :prefix_items,
    :contains,
    :min_contains,
    :max_contains,
    :unevaluated_items,
    :max_items,
    :min_items,
    :unique_items,
    :properties,
    :pattern_properties,
    :property_names,
    :additional_properties,
    :unevaluated_properties,
    :required,
    :max_properties,
    :min_properties,
    :dependent_schemas,
    :enum,
    :const,
    :default,
    :all_of,
    :any_of,
    :one_of,
    :not,
    :if_schema,
    :then_schema,
    :else_schema,
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
    :content_schema,
    :defs,
    :id,
    :anchor,
    :dynamic_anchor,
    :dynamic_ref,
    :schema_uri,
    :comment,
    :nullable
  ]

  @doc """
  Creates a new Schema struct from a map.
  Handles both Schema objects and Reference objects.
  """
  @spec new(map()) :: {:ok, t() | V3.Reference.t()} | {:error, String.t()}
  def new(data) when is_map(data) do
    data = KeyNormalizer.normalize_shallow(data)
    # Handle $ref
    if Map.has_key?(data, :"$ref") do
      V3.Reference.new(data)
    else
      with {:ok, items} <- parse_items(data),
           {:ok, prefix_items} <- parse_prefix_items(data),
           {:ok, contains} <- parse_contains(data),
           {:ok, properties} <- parse_properties(data),
           {:ok, pattern_properties} <- parse_pattern_properties(data),
           {:ok, property_names} <- parse_property_names(data),
           {:ok, additional_properties} <- parse_additional_properties(data),
           {:ok, unevaluated_properties} <- parse_unevaluated_properties(data),
           {:ok, unevaluated_items} <- parse_unevaluated_items(data),
           {:ok, dependent_schemas} <- parse_dependent_schemas(data),
           {:ok, if_then_else} <- parse_if_then_else(data),
           {:ok, defs} <- parse_defs(data),
           {:ok, all_of} <- parse_composition(data, :allOf),
           {:ok, any_of} <- parse_composition(data, :anyOf),
           {:ok, one_of} <- parse_composition(data, :oneOf),
           {:ok, not_schema} <- parse_not(data),
           {:ok, external_docs} <- parse_external_docs(data),
           {:ok, discriminator} <- parse_discriminator(data),
           {:ok, xml} <- parse_xml(data) do
        schema = %__MODULE__{
          type: parse_type(data[:type]),
          format: Map.get(data, :format),
          max_length: Map.get(data, :maxLength),
          min_length: Map.get(data, :minLength),
          pattern: Map.get(data, :pattern),
          maximum: Map.get(data, :maximum),
          exclusive_maximum: Map.get(data, :exclusiveMaximum),
          minimum: Map.get(data, :minimum),
          exclusive_minimum: Map.get(data, :exclusiveMinimum),
          multiple_of: Map.get(data, :multipleOf),
          items: items,
          prefix_items: prefix_items,
          contains: contains,
          min_contains: Map.get(data, :minContains),
          max_contains: Map.get(data, :maxContains),
          unevaluated_items: unevaluated_items,
          max_items: Map.get(data, :maxItems),
          min_items: Map.get(data, :minItems),
          unique_items: Map.get(data, :uniqueItems),
          properties: properties,
          pattern_properties: pattern_properties,
          property_names: property_names,
          additional_properties: additional_properties,
          unevaluated_properties: unevaluated_properties,
          required: Map.get(data, :required),
          max_properties: Map.get(data, :maxProperties),
          min_properties: Map.get(data, :minProperties),
          dependent_schemas: dependent_schemas,
          enum: Map.get(data, :enum),
          const: Map.get(data, :const),
          default: Map.get(data, :default),
          all_of: all_of,
          any_of: any_of,
          one_of: one_of,
          not: not_schema,
          if_schema: if_then_else.if_schema,
          then_schema: if_then_else.then_schema,
          else_schema: if_then_else.else_schema,
          title: Map.get(data, :title),
          description: Map.get(data, :description),
          example: Map.get(data, :example),
          examples: Map.get(data, :examples),
          external_docs: external_docs,
          deprecated: Map.get(data, :deprecated),
          discriminator: discriminator,
          read_only: Map.get(data, :readOnly),
          write_only: Map.get(data, :writeOnly),
          xml: xml,
          content_encoding: Map.get(data, :contentEncoding),
          content_media_type: Map.get(data, :contentMediaType),
          content_schema: Map.get(data, :contentSchema),
          defs: defs,
          id: Map.get(data, :"$id"),
          anchor: Map.get(data, :"$anchor"),
          dynamic_anchor: Map.get(data, :"$dynamicAnchor"),
          dynamic_ref: Map.get(data, :"$dynamicRef"),
          schema_uri: Map.get(data, :"$schema"),
          comment: Map.get(data, :"$comment"),
          nullable: Map.get(data, :nullable)
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
  defp parse_single_type("null"), do: :null
  defp parse_single_type(_), do: nil

  defp parse_items(%{:items => items_data}) when is_map(items_data) do
    new(items_data)
  end

  defp parse_items(_), do: {:ok, nil}

  defp parse_properties(%{:properties => props}) when is_map(props) do
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

  defp parse_additional_properties(%{:additionalProperties => false}), do: {:ok, false}
  defp parse_additional_properties(%{:additionalProperties => true}), do: {:ok, true}

  defp parse_additional_properties(%{:additionalProperties => schema_data})
       when is_map(schema_data) do
    new(schema_data)
  end

  defp parse_additional_properties(_), do: {:ok, nil}

  defp parse_unevaluated_properties(%{:unevaluatedProperties => false}), do: {:ok, false}
  defp parse_unevaluated_properties(%{:unevaluatedProperties => true}), do: {:ok, true}

  defp parse_unevaluated_properties(%{:unevaluatedProperties => schema_data})
       when is_map(schema_data) do
    new(schema_data)
  end

  defp parse_unevaluated_properties(_), do: {:ok, nil}

  defp parse_prefix_items(%{:prefixItems => prefix_items}) when is_list(prefix_items) do
    result =
      Enum.reduce_while(prefix_items, {:ok, []}, fn schema_data, {:ok, acc} ->
        case new(schema_data) do
          {:ok, schema} -> {:cont, {:ok, acc ++ [schema]}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_prefix_items(_), do: {:ok, nil}

  defp parse_contains(%{:contains => contains_data}) when is_map(contains_data) do
    new(contains_data)
  end

  defp parse_contains(_), do: {:ok, nil}

  defp parse_unevaluated_items(%{:unevaluatedItems => false}), do: {:ok, false}
  defp parse_unevaluated_items(%{:unevaluatedItems => true}), do: {:ok, true}

  defp parse_unevaluated_items(%{:unevaluatedItems => schema_data})
       when is_map(schema_data) do
    new(schema_data)
  end

  defp parse_unevaluated_items(_), do: {:ok, nil}

  defp parse_pattern_properties(%{:patternProperties => pattern_props})
       when is_map(pattern_props) do
    result =
      Enum.reduce_while(pattern_props, {:ok, %{}}, fn {pattern, value}, {:ok, acc} ->
        case new(value) do
          {:ok, schema} -> {:cont, {:ok, Map.put(acc, pattern, schema)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_pattern_properties(_), do: {:ok, nil}

  defp parse_property_names(%{:propertyNames => prop_names_data}) when is_map(prop_names_data) do
    new(prop_names_data)
  end

  defp parse_property_names(_), do: {:ok, nil}

  defp parse_dependent_schemas(%{:dependentSchemas => dep_schemas}) when is_map(dep_schemas) do
    result =
      Enum.reduce_while(dep_schemas, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case new(value) do
          {:ok, schema} -> {:cont, {:ok, Map.put(acc, key, schema)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_dependent_schemas(_), do: {:ok, nil}

  defp parse_if_then_else(data) do
    if_schema =
      if Map.has_key?(data, :if), do: parse_if_then_else_schema(data[:if]), else: {:ok, nil}

    then_schema =
      if Map.has_key?(data, :then), do: parse_if_then_else_schema(data[:then]), else: {:ok, nil}

    else_schema =
      if Map.has_key?(data, :else), do: parse_if_then_else_schema(data[:else]), else: {:ok, nil}

    with {:ok, if_val} <- if_schema,
         {:ok, then_val} <- then_schema,
         {:ok, else_val} <- else_schema do
      {:ok, %{if_schema: if_val, then_schema: then_val, else_schema: else_val}}
    end
  end

  defp parse_if_then_else_schema(nil), do: {:ok, nil}
  defp parse_if_then_else_schema(schema_data) when is_map(schema_data), do: new(schema_data)
  defp parse_if_then_else_schema(_), do: {:ok, nil}

  defp parse_defs(%{:"$defs" => defs_data}) when is_map(defs_data) do
    result =
      Enum.reduce_while(defs_data, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case new(value) do
          {:ok, schema} -> {:cont, {:ok, Map.put(acc, key, schema)}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp parse_defs(_), do: {:ok, nil}

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

  defp parse_not(%{:not => not_data}) when is_map(not_data) do
    new(not_data)
  end

  defp parse_not(_), do: {:ok, nil}

  defp parse_external_docs(%{:externalDocs => docs_data}) when is_map(docs_data) do
    ExternalDocumentation.new(docs_data)
  end

  defp parse_external_docs(_), do: {:ok, nil}

  defp parse_discriminator(%{:discriminator => disc_data}) when is_map(disc_data) do
    V3.Discriminator.new(disc_data)
  end

  defp parse_discriminator(_), do: {:ok, nil}

  defp parse_xml(%{:xml => xml_data}) when is_map(xml_data) do
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
      validate_prefix_items(schema.prefix_items, context),
      validate_contains(schema.contains, context),
      validate_min_max_contains(schema, context),
      validate_unevaluated_items(schema.unevaluated_items, context),
      validate_properties(schema.properties, context),
      validate_pattern_properties(schema.pattern_properties, context),
      validate_property_names(schema.property_names, context),
      validate_unevaluated_properties(schema.unevaluated_properties, context),
      validate_dependent_schemas(schema.dependent_schemas, context),
      validate_if_then_else(schema, context),
      validate_defs(schema.defs, context),
      validate_schema_references(schema, context),
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

  defp validate_items(%{type: :array, items: nil, prefix_items: nil, contains: nil}, context) do
    {:error, "#{context}: items, prefixItems, or contains is required when type is array"}
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

  defp validate_prefix_items(nil, _context), do: :ok

  defp validate_prefix_items(prefix_items, context) when is_list(prefix_items) do
    Validation.validate_list_items(
      prefix_items,
      fn schema, path ->
        validate(schema, path)
      end,
      "#{context}.prefixItems"
    )
  end

  defp validate_contains(nil, _context), do: :ok

  defp validate_contains(contains, context) do
    validate(contains, "#{context}.contains")
  end

  defp validate_min_max_contains(%{min_contains: nil, max_contains: nil}, _context), do: :ok

  defp validate_min_max_contains(%{min_contains: min, max_contains: nil}, context)
       when is_integer(min) do
    if min >= 0 do
      :ok
    else
      {:error, "#{context}.minContains must be >= 0"}
    end
  end

  defp validate_min_max_contains(%{min_contains: nil, max_contains: max}, context)
       when is_integer(max) do
    if max >= 0 do
      :ok
    else
      {:error, "#{context}.maxContains must be >= 0"}
    end
  end

  defp validate_min_max_contains(%{min_contains: min, max_contains: max}, context)
       when is_integer(min) and is_integer(max) do
    cond do
      min < 0 ->
        {:error, "#{context}.minContains must be >= 0"}

      max < 0 ->
        {:error, "#{context}.maxContains must be >= 0"}

      max < min ->
        {:error, "#{context}.maxContains must be >= minContains"}

      true ->
        :ok
    end
  end

  defp validate_min_max_contains(_, _context), do: :ok

  defp validate_unevaluated_items(nil, _context), do: :ok

  defp validate_unevaluated_items(unevaluated_items, _context)
       when is_boolean(unevaluated_items) do
    :ok
  end

  defp validate_unevaluated_items(unevaluated_items, context) do
    validate(unevaluated_items, "#{context}.unevaluatedItems")
  end

  defp validate_pattern_properties(nil, _context), do: :ok

  defp validate_pattern_properties(pattern_props, context) when is_map(pattern_props) do
    Validation.validate_map_values(
      pattern_props,
      fn schema, path ->
        validate(schema, path)
      end,
      "#{context}.patternProperties"
    )
  end

  defp validate_property_names(nil, _context), do: :ok

  defp validate_property_names(property_names, context) do
    validate(property_names, "#{context}.propertyNames")
  end

  defp validate_unevaluated_properties(nil, _context), do: :ok

  defp validate_unevaluated_properties(unevaluated_properties, _context)
       when is_boolean(unevaluated_properties) do
    :ok
  end

  defp validate_unevaluated_properties(unevaluated_properties, context) do
    validate(unevaluated_properties, "#{context}.unevaluatedProperties")
  end

  defp validate_dependent_schemas(nil, _context), do: :ok

  defp validate_dependent_schemas(dep_schemas, context) when is_map(dep_schemas) do
    Validation.validate_map_values(
      dep_schemas,
      fn schema, path ->
        validate(schema, path)
      end,
      "#{context}.dependentSchemas"
    )
  end

  defp validate_if_then_else(%{if_schema: nil}, _context), do: :ok

  defp validate_if_then_else(
         %{if_schema: if_schema, then_schema: then_schema, else_schema: else_schema},
         context
       ) do
    validations = [
      validate(if_schema, "#{context}.if"),
      validate_then_schema(then_schema, context),
      validate_else_schema(else_schema, context)
    ]

    Validation.combine_results(validations)
  end

  defp validate_if_then_else(_, _context), do: :ok

  defp validate_then_schema(nil, _context), do: :ok
  defp validate_then_schema(then_schema, context), do: validate(then_schema, "#{context}.then")

  defp validate_else_schema(nil, _context), do: :ok
  defp validate_else_schema(else_schema, context), do: validate(else_schema, "#{context}.else")

  defp validate_defs(nil, _context), do: :ok

  defp validate_defs(defs, context) when is_map(defs) do
    Validation.validate_map_values(
      defs,
      fn schema, path ->
        validate(schema, path)
      end,
      "#{context}.$defs"
    )
  end

  defp validate_schema_references(schema, context) do
    validations = [
      Validation.validate_type(schema.id, :string, "#{context}.$id"),
      validate_id_format(schema.id, context),
      Validation.validate_type(schema.anchor, :string, "#{context}.$anchor"),
      Validation.validate_type(schema.dynamic_anchor, :string, "#{context}.$dynamicAnchor"),
      Validation.validate_type(schema.dynamic_ref, :string, "#{context}.$dynamicRef"),
      validate_dynamic_ref_format(schema.dynamic_ref, context),
      Validation.validate_type(schema.schema_uri, :string, "#{context}.$schema"),
      validate_schema_uri_format(schema.schema_uri, context),
      Validation.validate_type(schema.comment, :string, "#{context}.$comment")
    ]

    Validation.combine_results(validations)
  end

  defp validate_id_format(nil, _context), do: :ok
  defp validate_id_format(id, context), do: Validation.validate_format(id, :uri, "#{context}.$id")

  defp validate_dynamic_ref_format(nil, _context), do: :ok

  defp validate_dynamic_ref_format(dynamic_ref, context),
    do: Validation.validate_format(dynamic_ref, :uri, "#{context}.$dynamicRef")

  defp validate_schema_uri_format(nil, _context), do: :ok

  defp validate_schema_uri_format(schema_uri, context),
    do: Validation.validate_format(schema_uri, :uri, "#{context}.$schema")
end
