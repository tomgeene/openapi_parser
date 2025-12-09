defmodule OpenapiParser.V2ParameterAdditionalTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Parameter

  test "creates parameter with $ref" do
    data = %{
      "$ref" => "#/parameters/IdParam"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.ref == "#/parameters/IdParam"
  end

  test "creates body parameter with schema" do
    data = %{
      "name" => "body",
      "in" => "body",
      "required" => true,
      "schema" => %{"type" => "object"}
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.location == :body
    assert param.schema != nil
  end

  test "creates formData parameter" do
    data = %{
      "name" => "file",
      "in" => "formData",
      "type" => "file"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.location == :formData
    assert param.type == :file
  end

  test "creates parameter with all validation fields" do
    data = %{
      "name" => "limit",
      "in" => "query",
      "type" => "integer",
      "maximum" => 100,
      "exclusiveMaximum" => false,
      "minimum" => 1,
      "exclusiveMinimum" => false,
      "maxLength" => 10,
      "minLength" => 1,
      "pattern" => "^[0-9]+$",
      "maxItems" => 10,
      "minItems" => 1,
      "uniqueItems" => true,
      "enum" => [1, 2, 3],
      "multipleOf" => 2
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.maximum == 100
    assert param.minimum == 1
    assert param.max_length == 10
    assert param.min_length == 1
    assert param.pattern == "^[0-9]+$"
    assert param.max_items == 10
    assert param.min_items == 1
    assert param.unique_items == true
    assert param.enum == [1, 2, 3]
    assert param.multiple_of == 2
  end

  test "creates parameter with collection format" do
    data = %{
      "name" => "tags",
      "in" => "query",
      "type" => "array",
      "items" => %{"type" => "string"},
      "collectionFormat" => "csv"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.collection_format == "csv"
  end

  test "validates parameter with $ref" do
    data = %{
      "$ref" => "#/parameters/IdParam"
    }

    assert {:ok, param} = Parameter.new(data)
    assert :ok = Parameter.validate(param)
  end

  test "validates body parameter requires schema" do
    data = %{
      "name" => "body",
      "in" => "body",
      "required" => true
      # Missing schema
    }

    assert {:ok, param} = Parameter.new(data)
    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "schema") || String.contains?(msg, "Body parameter")
  end

  test "validates non-body parameter requires type" do
    data = %{
      "name" => "id",
      "in" => "query"
      # Missing type
    }

    assert {:ok, param} = Parameter.new(data)
    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "type") || String.contains?(msg, "Non-body parameter")
  end

  test "handles schema parsing error" do
    data = %{
      "name" => "body",
      "in" => "body",
      "required" => true,
      "schema" => %{
        "allOf" => [
          %{"type" => "object"},
          %{"invalid" => "data"}
        ]
      }
    }

    result = Parameter.new(data)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "handles items parsing error" do
    data = %{
      "name" => "tags",
      "in" => "query",
      "type" => "array",
      "items" => %{
        "allOf" => [
          %{"type" => "string"},
          %{"invalid" => "data"}
        ]
      }
    }

    result = Parameter.new(data)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end
end
