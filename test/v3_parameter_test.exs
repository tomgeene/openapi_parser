defmodule OpenapiParser.V3ParameterTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Parameter
  alias OpenapiParser.Spec.V3.Schema

  test "creates parameter with basic data" do
    data = %{
      "name" => "id",
      "in" => "path"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.name == "id"
    assert param.location == :path
  end

  test "creates parameter with all locations" do
    for location <- ["path", "query", "header", "cookie"] do
      data = %{"name" => "test", "in" => location}
      assert {:ok, param} = Parameter.new(data)
      assert param.location == String.to_atom(location)
    end
  end

  test "creates parameter with schema" do
    data = %{
      "name" => "id",
      "in" => "query",
      "schema" => %{"type" => "string"}
    }

    assert {:ok, param} = Parameter.new(data)
    assert %Schema{} = param.schema
    assert param.schema.type == :string
  end

  test "creates parameter with description and flags" do
    data = %{
      "name" => "id",
      "in" => "query",
      "description" => "User ID",
      "required" => true,
      "deprecated" => false,
      "allowEmptyValue" => true
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.description == "User ID"
    assert param.required == true
    assert param.deprecated == false
    assert param.allow_empty_value == true
  end

  test "creates parameter with style and explode" do
    data = %{
      "name" => "filter",
      "in" => "query",
      "style" => "form",
      "explode" => true,
      "allowReserved" => false
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.style == "form"
    assert param.explode == true
    assert param.allow_reserved == false
  end

  test "creates parameter with example" do
    data = %{
      "name" => "id",
      "in" => "query",
      "example" => "12345"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.example == "12345"
  end

  test "creates parameter with examples" do
    data = %{
      "name" => "id",
      "in" => "query",
      "examples" => %{
        "basic" => %{"value" => "123"}
      }
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.examples != nil
  end

  test "validates parameter with required fields" do
    param = %Parameter{
      name: "id",
      location: :path,
      required: true,
      schema: %Schema{type: :string}
    }

    assert :ok = Parameter.validate(param)
  end

  test "fails validation when name is missing" do
    param = %Parameter{location: :query}

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "name")
  end

  test "fails validation when location is missing" do
    param = %Parameter{name: "id"}

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "in")
  end

  test "validates path parameter must be required" do
    param = %Parameter{
      name: "id",
      location: :path,
      required: false,
      schema: %Schema{type: :string}
    }

    assert {:error, msg} = Parameter.validate(param)
    assert String.contains?(msg, "Path parameter")
  end

  test "validates query parameter can be optional" do
    param = %Parameter{
      name: "filter",
      location: :query,
      required: false,
      schema: %Schema{type: :string}
    }

    assert :ok = Parameter.validate(param)
  end

  test "validates with custom context" do
    param = %Parameter{
      name: "id",
      location: :path,
      required: true,
      schema: %Schema{type: :string}
    }

    assert :ok = Parameter.validate(param, "paths./users/{id}.parameters[0]")
  end

  test "creates parameter with examples containing references" do
    data = %{
      "name" => "id",
      "in" => "query",
      "examples" => %{
        "ref" => %{"$ref" => "#/components/examples/MyExample"}
      }
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.examples != nil
    assert param.examples["ref"].ref == "#/components/examples/MyExample"
  end

  test "creates parameter with content" do
    data = %{
      "name" => "body",
      "in" => "query",
      "content" => %{
        "application/json" => %{
          "schema" => %{"type" => "object"}
        }
      }
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.content != nil
    assert Map.has_key?(param.content, "application/json")
  end

  test "validates parameter fails when both schema and content present" do
    param = %Parameter{
      name: "id",
      location: :query,
      schema: %Schema{type: :string},
      content: %{"application/json" => %OpenapiParser.Spec.V3.MediaType{}}
    }

    assert {:error, msg} = Parameter.validate(param)
    assert msg =~ "mutually exclusive"
  end

  test "validates parameter fails when neither schema nor content present" do
    param = %Parameter{
      name: "id",
      location: :query,
      schema: nil,
      content: nil
    }

    assert {:error, msg} = Parameter.validate(param)
    assert msg =~ "Either schema or content is required"
  end

  test "validates parameter with content must have exactly one entry" do
    param = %Parameter{
      name: "id",
      location: :query,
      content: %{
        "application/json" => %OpenapiParser.Spec.V3.MediaType{},
        "application/xml" => %OpenapiParser.Spec.V3.MediaType{}
      }
    }

    assert {:error, msg} = Parameter.validate(param)
    assert msg =~ "exactly one entry"
  end

  test "validates parameter with examples map" do
    alias OpenapiParser.Spec.V3.Example
    alias OpenapiParser.Spec.V3.Reference

    param = %Parameter{
      name: "id",
      location: :query,
      schema: %Schema{type: :string},
      examples: %{
        "example1" => %Example{value: "test"},
        "ref1" => %Reference{ref: "#/components/examples/Test"}
      }
    }

    assert :ok = Parameter.validate(param)
  end

  test "handles unknown location gracefully" do
    data = %{
      "name" => "test",
      "in" => "unknown"
    }

    assert {:ok, param} = Parameter.new(data)
    assert param.location == nil
  end

  test "validates parameter with valid single content entry" do
    param = %Parameter{
      name: "data",
      location: :query,
      content: %{
        "application/json" => %OpenapiParser.Spec.V3.MediaType{}
      }
    }

    assert :ok = Parameter.validate(param)
  end
end
