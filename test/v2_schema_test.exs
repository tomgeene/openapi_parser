defmodule OpenapiParser.V2SchemaTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Schema

  test "creates schema with $ref" do
    data = %{
      "$ref" => "#/definitions/User"
    }

    assert {:ok, schema} = Schema.new(data)
    assert schema.ref == "#/definitions/User"
  end

  test "creates schema with all fields" do
    data = %{
      "type" => "object",
      "format" => "email",
      "title" => "User Schema",
      "description" => "User object",
      "properties" => %{
        "name" => %{"type" => "string"}
      },
      "required" => ["name"],
      "discriminator" => "type",
      "readOnly" => true,
      "example" => %{"name" => "John"}
    }

    assert {:ok, schema} = Schema.new(data)
    assert schema.type == :object
    assert schema.format == "email"
    assert schema.title == "User Schema"
    assert schema.description == "User object"
    assert map_size(schema.properties) == 1
    assert schema.required == ["name"]
    assert schema.discriminator == "type"
    assert schema.read_only == true
    assert schema.example == %{"name" => "John"}
  end

  test "creates schema with allOf" do
    data = %{
      "allOf" => [
        %{"type" => "object"},
        %{"properties" => %{"name" => %{"type" => "string"}}}
      ]
    }

    assert {:ok, schema} = Schema.new(data)
    assert length(schema.all_of) == 2
  end

  test "creates schema with file type" do
    data = %{
      "type" => "file"
    }

    assert {:ok, schema} = Schema.new(data)
    assert schema.type == :file
  end

  test "validates schema with $ref" do
    data = %{
      "$ref" => "#/definitions/User"
    }

    assert {:ok, schema} = Schema.new(data)
    assert :ok = Schema.validate(schema)
  end

  test "validates schema" do
    data = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    assert {:ok, schema} = Schema.new(data)
    assert :ok = Schema.validate(schema)
  end

  test "validates array schema requires items" do
    data = %{
      "type" => "array"
      # Missing items
    }

    assert {:ok, schema} = Schema.new(data)
    assert {:error, msg} = Schema.validate(schema)
    assert String.contains?(msg, "items is required")
  end

  test "handles schema with invalid property type" do
    data = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "invalid_type"}
      }
    }

    # Should still parse - invalid_type will be parsed as nil
    assert {:ok, _schema} = Schema.new(data)
  end
end
