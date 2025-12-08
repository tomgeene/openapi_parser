defmodule OpenapiParser.V2ParameterTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Parameter
  alias OpenapiParser.Spec.V2.Schema

  test "creates parameter with basic data" do
    data = %{
      "name" => "id",
      "in" => "path",
      "type" => "string"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.name == "id"
    assert param.location == :path
    assert param.type == :string
  end

  test "creates parameter with all locations" do
    for location <- ["path", "query", "header", "formData"] do
      data = %{"name" => "test", "in" => location, "type" => "string"}
      assert {:ok, param} = Parameter.new(data)
      assert param.location == String.to_atom(location)
    end
  end

  test "creates body parameter with schema" do
    data = %{
      "name" => "body",
      "in" => "body",
      "schema" => %{"type" => "object"}
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.location == :body
    assert %Schema{} = param.schema
  end

  test "creates parameter with all primitive types" do
    for type <- ["string", "number", "integer", "boolean"] do
      data = %{"name" => "test", "in" => "query", "type" => type}
      assert {:ok, param} = Parameter.new(data)
      assert param.type == String.to_atom(type)
    end
  end

  test "creates array parameter with items" do
    data = %{
      "name" => "ids",
      "in" => "query",
      "type" => "array",
      "items" => %{"type" => "integer"}
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.type == :array
    assert %Schema{} = param.items
  end

  test "creates file parameter" do
    data = %{
      "name" => "file",
      "in" => "formData",
      "type" => "file"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.type == :file
  end

  test "creates parameter with description and flags" do
    data = %{
      "name" => "id",
      "in" => "query",
      "type" => "string",
      "description" => "User ID",
      "required" => true,
      "allowEmptyValue" => true
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.description == "User ID"
    assert param.required == true
    assert param.allow_empty_value == true
  end

  test "creates parameter with collection format" do
    data = %{
      "name" => "ids",
      "in" => "query",
      "type" => "array",
      "items" => %{"type" => "integer"},
      "collectionFormat" => "csv"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.collection_format == "csv"
  end

  test "creates parameter with validation constraints" do
    data = %{
      "name" => "age",
      "in" => "query",
      "type" => "integer",
      "minimum" => 0,
      "maximum" => 120
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.minimum == 0
    assert param.maximum == 120
  end

  test "validates parameter with required fields" do
    param = %Parameter{
      name: "id",
      location: :path,
      required: true,
      type: :string
    }

    assert :ok = Parameter.validate(param)
  end

  test "validates body parameter" do
    param = %Parameter{
      name: "body",
      location: :body,
      schema: %Schema{type: :object}
    }

    assert :ok = Parameter.validate(param)
  end

  test "fails validation when name is missing" do
    param = %Parameter{location: :query, type: :string}

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "name")
  end

  test "fails validation when location is missing" do
    param = %Parameter{name: "id", type: :string}

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "in")
  end

  test "validates path parameter must be required" do
    param = %Parameter{
      name: "id",
      location: :path,
      required: false,
      type: :string
    }

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "Path parameter")
  end

  test "fails validation when body parameter missing schema" do
    param = %Parameter{
      name: "body",
      location: :body
    }

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "Body parameter")
  end

  test "fails validation when non-body parameter missing type" do
    param = %Parameter{
      name: "id",
      location: :query
    }

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "Non-body parameter")
  end

  test "validates with custom context" do
    param = %Parameter{
      name: "id",
      location: :path,
      required: true,
      type: :string
    }

    assert :ok = Parameter.validate(param, "paths./users/{id}.parameters[0]")
  end
end
