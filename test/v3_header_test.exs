defmodule OpenapiParser.V3HeaderTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Header
  alias OpenapiParser.Spec.V3.Schema
  alias OpenapiParser.Spec.V3.Example
  alias OpenapiParser.Spec.V3.Reference

  test "creates Header with minimal data" do
    data = %{}

    assert {:ok, header} = Header.new(data)
    assert header.description == nil
    assert header.required == false
  end

  test "creates Header with description" do
    data = %{
      "description" => "Custom header",
      "required" => true,
      "deprecated" => false
    }

    assert {:ok, header} = Header.new(data)
    assert header.description == "Custom header"
    assert header.required == true
    assert header.deprecated == false
  end

  test "creates Header with schema" do
    data = %{
      "schema" => %{
        "type" => "string"
      }
    }

    assert {:ok, header} = Header.new(data)
    assert %Schema{} = header.schema
    assert header.schema.type == :string
  end

  test "creates Header with style parameters" do
    data = %{
      "style" => "simple",
      "explode" => true,
      "allowReserved" => false
    }

    assert {:ok, header} = Header.new(data)
    assert header.style == "simple"
    assert header.explode == true
    assert header.allow_reserved == false
  end

  test "creates Header with example" do
    data = %{
      "example" => "Bearer token123"
    }

    assert {:ok, header} = Header.new(data)
    assert header.example == "Bearer token123"
  end

  test "creates Header with examples map" do
    data = %{
      "examples" => %{
        "example1" => %{
          "summary" => "Example 1",
          "value" => "value1"
        },
        "example2" => %{
          "summary" => "Example 2",
          "value" => "value2"
        }
      }
    }

    assert {:ok, header} = Header.new(data)
    assert map_size(header.examples) == 2
    assert %Example{} = header.examples["example1"]
    assert header.examples["example1"].summary == "Example 1"
  end

  test "creates Header with examples containing references" do
    data = %{
      "examples" => %{
        "ref_example" => %{
          "$ref" => "#/components/examples/MyExample"
        }
      }
    }

    assert {:ok, header} = Header.new(data)
    assert %Reference{} = header.examples["ref_example"]
    assert header.examples["ref_example"].ref == "#/components/examples/MyExample"
  end

  test "creates Header with mixed examples and references" do
    data = %{
      "examples" => %{
        "inline" => %{
          "summary" => "Inline example",
          "value" => "test"
        },
        "referenced" => %{
          "$ref" => "#/components/examples/Ref"
        }
      }
    }

    assert {:ok, header} = Header.new(data)
    assert %Example{} = header.examples["inline"]
    assert %Reference{} = header.examples["referenced"]
  end

  test "validates minimal header" do
    header = %Header{}

    assert :ok = Header.validate(header)
  end

  test "validates header with schema" do
    schema = %Schema{type: :string}
    header = %Header{schema: schema}

    assert :ok = Header.validate(header)
  end

  test "validates with custom context" do
    header = %Header{}

    assert :ok = Header.validate(header, "components.headers.CustomHeader")
  end

  test "validates header with examples" do
    example = %Example{summary: "Test", value: "test_value"}
    header = %Header{examples: %{"test" => example}}

    assert :ok = Header.validate(header)
  end

  test "validates header with reference examples" do
    ref = %Reference{ref: "#/components/examples/Test"}
    header = %Header{examples: %{"test" => ref}}

    assert :ok = Header.validate(header)
  end

  test "validates header with mixed examples" do
    example = %Example{summary: "Test", value: "test_value"}
    ref = %Reference{ref: "#/components/examples/Test"}
    header = %Header{examples: %{"inline" => example, "ref" => ref}}

    assert :ok = Header.validate(header)
  end

  test "validates header with allowEmptyValue" do
    header = %Header{allow_empty_value: true}

    assert :ok = Header.validate(header)
  end
end
