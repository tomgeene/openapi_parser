defmodule OpenapiParser.V2HeaderTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Header
  alias OpenapiParser.Spec.V2.Schema

  test "creates Header with basic string type" do
    data = %{"type" => "string"}

    assert {:ok, header} = Header.new(data)
    assert header.type == :string
  end

  test "creates Header with description" do
    data = %{
      "type" => "integer",
      "description" => "Rate limit"
    }

    assert {:ok, header} = Header.new(data)
    assert header.type == :integer
    assert header.description == "Rate limit"
  end

  test "creates Header with all primitive types" do
    for type <- ["string", "number", "integer", "boolean", "array"] do
      items = if type == "array", do: %{"type" => "string"}, else: nil
      data = if items, do: %{"type" => type, "items" => items}, else: %{"type" => type}
      assert {:ok, header} = Header.new(data)
      assert header.type == String.to_atom(type)
    end
  end

  test "creates Header with format" do
    data = %{
      "type" => "string",
      "format" => "uuid"
    }

    assert {:ok, header} = Header.new(data)
    assert header.format == "uuid"
  end

  test "creates Header with array items" do
    data = %{
      "type" => "array",
      "items" => %{
        "type" => "string"
      }
    }

    assert {:ok, header} = Header.new(data)
    assert header.type == :array
    assert %Schema{} = header.items
  end

  test "creates Header with validation constraints" do
    data = %{
      "type" => "integer",
      "minimum" => 1,
      "maximum" => 100,
      "exclusiveMinimum" => false,
      "exclusiveMaximum" => true
    }

    assert {:ok, header} = Header.new(data)
    assert header.minimum == 1
    assert header.maximum == 100
  end

  test "creates Header with enum" do
    data = %{
      "type" => "string",
      "enum" => ["red", "green", "blue"]
    }

    assert {:ok, header} = Header.new(data)
    assert header.enum == ["red", "green", "blue"]
  end

  test "validates Header with required type" do
    header = %Header{type: :string}

    assert :ok = Header.validate(header)
  end

  test "fails validation when type is missing" do
    header = %Header{type: nil}

    assert {:error, msg} = Header.validate(header)
    assert String.contains?(msg, "Required field(s) missing")
  end

  test "fails validation when array type has no items" do
    header = %Header{type: :array, items: nil}

    assert {:error, msg} = Header.validate(header)
    assert String.contains?(msg, "items is required")
  end

  test "validates array with items" do
    items = %Schema{type: :string}
    header = %Header{type: :array, items: items}

    assert :ok = Header.validate(header)
  end
end
