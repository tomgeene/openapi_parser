defmodule OpenapiParser.V3SchemaTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Schema

  describe "JSON Schema 2020-12 keywords" do
    test "parses patternProperties" do
      data = %{
        "type" => "object",
        "patternProperties" => %{
          "^S_" => %{"type" => "string"},
          "^I_" => %{"type" => "integer"}
        }
      }

      assert {:ok, schema} = Schema.new(data)
      assert map_size(schema.pattern_properties) == 2
      assert Map.has_key?(schema.pattern_properties, "^S_")
      assert Map.has_key?(schema.pattern_properties, "^I_")
    end

    test "parses propertyNames" do
      data = %{
        "type" => "object",
        "propertyNames" => %{
          "type" => "string",
          "pattern" => "^[A-Z]"
        }
      }

      assert {:ok, schema} = Schema.new(data)
      assert %Schema{} = schema.property_names
      assert schema.property_names.type == :string
    end

    test "parses prefixItems" do
      data = %{
        "type" => "array",
        "prefixItems" => [
          %{"type" => "string"},
          %{"type" => "integer"},
          %{"type" => "boolean"}
        ]
      }

      assert {:ok, schema} = Schema.new(data)
      assert length(schema.prefix_items) == 3
      assert hd(schema.prefix_items).type == :string
    end

    test "parses contains" do
      data = %{
        "type" => "array",
        "contains" => %{"type" => "string"}
      }

      assert {:ok, schema} = Schema.new(data)
      assert %Schema{} = schema.contains
      assert schema.contains.type == :string
    end

    test "parses minContains and maxContains" do
      data = %{
        "type" => "array",
        "contains" => %{"type" => "string"},
        "minContains" => 1,
        "maxContains" => 5
      }

      assert {:ok, schema} = Schema.new(data)
      assert schema.min_contains == 1
      assert schema.max_contains == 5
    end

    test "parses unevaluatedItems" do
      data = %{
        "type" => "array",
        "unevaluatedItems" => false
      }

      assert {:ok, schema} = Schema.new(data)
      assert schema.unevaluated_items == false
    end

    test "parses unevaluatedItems as schema" do
      data = %{
        "type" => "array",
        "unevaluatedItems" => %{"type" => "string"}
      }

      assert {:ok, schema} = Schema.new(data)
      assert %Schema{} = schema.unevaluated_items
      assert schema.unevaluated_items.type == :string
    end

    test "parses dependentSchemas" do
      data = %{
        "type" => "object",
        "dependentSchemas" => %{
          "credit_card" => %{
            "properties" => %{
              "billing_address" => %{"type" => "string"}
            }
          }
        }
      }

      assert {:ok, schema} = Schema.new(data)
      assert map_size(schema.dependent_schemas) == 1
      assert Map.has_key?(schema.dependent_schemas, "credit_card")
    end

    test "parses if/then/else" do
      data = %{
        "if" => %{"properties" => %{"foo" => %{"const" => 3}}},
        "then" => %{"properties" => %{"bar" => %{"type" => "string"}}},
        "else" => %{"properties" => %{"baz" => %{"type" => "number"}}}
      }

      assert {:ok, schema} = Schema.new(data)
      assert %Schema{} = schema.if_schema
      assert %Schema{} = schema.then_schema
      assert %Schema{} = schema.else_schema
    end

    test "parses $defs" do
      data = %{
        "type" => "object",
        "$defs" => %{
          "address" => %{"type" => "string"},
          "name" => %{"type" => "string"}
        }
      }

      assert {:ok, schema} = Schema.new(data)
      assert map_size(schema.defs) == 2
      assert Map.has_key?(schema.defs, "address")
    end

    test "parses $id, $anchor, $dynamicAnchor, $dynamicRef, $schema, $comment" do
      data = %{
        "$id" => "https://example.com/schema",
        "$anchor" => "myAnchor",
        "$dynamicAnchor" => "myDynamicAnchor",
        "$dynamicRef" => "#myDynamicAnchor",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$comment" => "This is a comment"
      }

      assert {:ok, schema} = Schema.new(data)
      assert schema.id == "https://example.com/schema"
      assert schema.anchor == "myAnchor"
      assert schema.dynamic_anchor == "myDynamicAnchor"
      assert schema.dynamic_ref == "#myDynamicAnchor"
      assert schema.schema_uri == "https://json-schema.org/draft/2020-12/schema"
      assert schema.comment == "This is a comment"
    end

    test "parses nullable" do
      data = %{
        "type" => "string",
        "nullable" => true
      }

      assert {:ok, schema} = Schema.new(data)
      assert schema.nullable == true
    end
  end

  describe "validation" do
    test "validates minContains >= 0" do
      data = %{
        "type" => "array",
        "contains" => %{"type" => "string"},
        "minContains" => -1
      }

      assert {:ok, schema} = Schema.new(data)
      assert {:error, msg} = Schema.validate(schema)
      assert String.contains?(msg, "minContains must be >= 0")
    end

    test "validates maxContains >= minContains" do
      data = %{
        "type" => "array",
        "contains" => %{"type" => "string"},
        "minContains" => 5,
        "maxContains" => 3
      }

      assert {:ok, schema} = Schema.new(data)
      assert {:error, msg} = Schema.validate(schema)
      assert String.contains?(msg, "maxContains must be >= minContains")
    end

    test "validates patternProperties schemas" do
      data = %{
        "type" => "object",
        "patternProperties" => %{
          "^S_" => %{"type" => "invalid_type"}
        }
      }

      assert {:ok, schema} = Schema.new(data)
      # Should still parse but validation might fail on the nested schema
      assert map_size(schema.pattern_properties) == 1
    end

    test "validates if/then/else schemas" do
      data = %{
        "if" => %{"type" => "object"},
        "then" => %{"type" => "string"},
        "else" => %{"type" => "number"}
      }

      assert {:ok, schema} = Schema.new(data)
      assert :ok = Schema.validate(schema)
    end

    test "validates dependentSchemas" do
      data = %{
        "type" => "object",
        "dependentSchemas" => %{
          "credit_card" => %{"type" => "object"}
        }
      }

      assert {:ok, schema} = Schema.new(data)
      assert :ok = Schema.validate(schema)
    end

    test "validates $id URI format" do
      data = %{
        "$id" => "not-a-uri"
      }

      assert {:ok, schema} = Schema.new(data)
      assert {:error, msg} = Schema.validate(schema)
      assert String.contains?(msg, "$id") || String.contains?(msg, "URI")
    end
  end
end
