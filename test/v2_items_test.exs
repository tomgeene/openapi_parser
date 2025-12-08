defmodule OpenapiParser.Spec.V2.ItemsTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Items

  describe "new/1" do
    test "creates Items with basic string type" do
      data = %{"type" => "string"}

      assert {:ok, items} = Items.new(data)
      assert items.type == :string
      assert items.format == nil
    end

    test "creates Items with format" do
      data = %{
        "type" => "string",
        "format" => "uuid"
      }

      assert {:ok, items} = Items.new(data)
      assert items.type == :string
      assert items.format == "uuid"
    end

    test "creates Items with all primitive types" do
      for type <- ["string", "number", "integer", "boolean", "array"] do
        data = %{"type" => type}
        assert {:ok, items} = Items.new(data)
        assert items.type == String.to_atom(type)
      end
    end

    test "creates Items with collection format" do
      for format <- ["csv", "ssv", "tsv", "pipes", "multi"] do
        data = %{
          "type" => "array",
          "collectionFormat" => format
        }

        assert {:ok, items} = Items.new(data)
        assert items.collection_format == String.to_atom(format)
      end
    end

    test "creates Items with nested items" do
      data = %{
        "type" => "array",
        "items" => %{
          "type" => "string"
        }
      }

      assert {:ok, items} = Items.new(data)
      assert items.type == :array
      assert items.items != nil
      assert items.items.type == :string
    end

    test "creates Items with validation constraints" do
      data = %{
        "type" => "integer",
        "minimum" => 1,
        "maximum" => 100,
        "exclusiveMinimum" => false,
        "exclusiveMaximum" => false,
        "multipleOf" => 5
      }

      assert {:ok, items} = Items.new(data)
      assert items.minimum == 1
      assert items.maximum == 100
      assert items.exclusive_minimum == false
      assert items.exclusive_maximum == false
      assert items.multiple_of == 5
    end

    test "creates Items with string constraints" do
      data = %{
        "type" => "string",
        "minLength" => 5,
        "maxLength" => 50,
        "pattern" => "^[a-z]+$"
      }

      assert {:ok, items} = Items.new(data)
      assert items.min_length == 5
      assert items.max_length == 50
      assert items.pattern == "^[a-z]+$"
    end

    test "creates Items with array constraints" do
      data = %{
        "type" => "array",
        "minItems" => 1,
        "maxItems" => 10,
        "uniqueItems" => true
      }

      assert {:ok, items} = Items.new(data)
      assert items.min_items == 1
      assert items.max_items == 10
      assert items.unique_items == true
    end

    test "creates Items with enum" do
      data = %{
        "type" => "string",
        "enum" => ["red", "green", "blue"]
      }

      assert {:ok, items} = Items.new(data)
      assert items.enum == ["red", "green", "blue"]
    end

    test "creates Items with default value" do
      data = %{
        "type" => "string",
        "default" => "default-value"
      }

      assert {:ok, items} = Items.new(data)
      assert items.default == "default-value"
    end

    test "handles unknown type gracefully" do
      data = %{"type" => "unknown"}

      assert {:ok, items} = Items.new(data)
      assert items.type == nil
    end

    test "handles unknown collection format gracefully" do
      data = %{
        "type" => "array",
        "collectionFormat" => "unknown"
      }

      assert {:ok, items} = Items.new(data)
      assert items.collection_format == nil
    end
  end

  describe "validate/1" do
    test "validates Items with required type" do
      items = %Items{type: :string}

      assert :ok = Items.validate(items)
    end

    test "fails validation when type is missing" do
      items = %Items{type: nil}

      assert {:error, msg} = Items.validate(items)
      assert String.contains?(msg, "Required field(s) missing")
    end

    test "validates all valid types" do
      for type <- [:string, :number, :integer, :boolean, :array] do
        items = %Items{type: type}
        assert :ok = Items.validate(items)
      end
    end

    test "fails validation with invalid type" do
      items = %Items{type: :invalid}

      assert {:error, msg} = Items.validate(items)
      assert String.contains?(msg, "must be one of")
    end

    test "validates format as string" do
      items = %Items{type: :string, format: "uuid"}

      assert :ok = Items.validate(items)
    end

    test "validates all collection formats" do
      for format <- [:csv, :ssv, :tsv, :pipes, :multi] do
        items = %Items{type: :array, collection_format: format}
        assert :ok = Items.validate(items)
      end
    end

    test "fails validation with invalid collection format" do
      items = %Items{type: :array, collection_format: :invalid}

      assert {:error, msg} = Items.validate(items)
      assert String.contains?(msg, "must be one of")
    end

    test "validates nested items recursively" do
      nested_items = %Items{type: :string}
      items = %Items{type: :array, items: nested_items}

      assert :ok = Items.validate(items)
    end

    test "fails validation when nested items are invalid" do
      nested_items = %Items{type: nil}
      items = %Items{type: :array, items: nested_items}

      assert {:error, _msg} = Items.validate(items)
    end
  end
end
