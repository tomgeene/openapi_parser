defmodule OpenapiParser.V3ExampleReferenceTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Example
  alias OpenapiParser.Spec.V3.Reference

  describe "Example.new/1" do
    test "creates example with value" do
      data = %{
        "summary" => "A simple example",
        "description" => "Detailed description",
        "value" => %{"name" => "John", "age" => 30}
      }

      assert {:ok, example} = Example.new(data)
      assert example.summary == "A simple example"
      assert example.description == "Detailed description"
      assert example.value == %{"name" => "John", "age" => 30}
    end

    test "creates example with externalValue" do
      data = %{
        "summary" => "External example",
        "externalValue" => "https://example.com/examples/user.json"
      }

      assert {:ok, example} = Example.new(data)
      assert example.external_value == "https://example.com/examples/user.json"
    end

    test "creates empty example" do
      data = %{}

      assert {:ok, example} = Example.new(data)
      assert example.value == nil
      assert example.external_value == nil
    end

    test "returns error for non-map input" do
      assert {:error, msg} = Example.new("not a map")
      assert msg =~ "must be a map"
    end

    test "returns error for nil input" do
      assert {:error, msg} = Example.new(nil)
      assert msg =~ "must be a map"
    end

    test "returns error for list input" do
      assert {:error, msg} = Example.new([])
      assert msg =~ "must be a map"
    end
  end

  describe "Example.validate/2" do
    test "validates example with value" do
      example = %Example{value: "test value"}

      assert :ok = Example.validate(example)
    end

    test "validates example with externalValue" do
      example = %Example{external_value: "https://example.com/data.json"}

      assert :ok = Example.validate(example)
    end

    test "returns error when both value and externalValue present" do
      example = %Example{
        value: "some value",
        external_value: "https://example.com/data.json"
      }

      assert {:error, msg} = Example.validate(example)
      assert msg =~ "mutually exclusive"
    end

    test "validates empty example" do
      example = %Example{}

      assert :ok = Example.validate(example)
    end

    test "validates with custom context" do
      example = %Example{value: "test"}

      assert :ok = Example.validate(example, "components.examples.MyExample")
    end

    test "validates example with summary and description" do
      example = %Example{
        summary: "Test summary",
        description: "Test description",
        value: "test"
      }

      assert :ok = Example.validate(example)
    end
  end

  describe "Reference.new/1" do
    test "creates reference with $ref" do
      data = %{
        "$ref" => "#/components/schemas/User"
      }

      assert {:ok, ref} = Reference.new(data)
      assert ref.ref == "#/components/schemas/User"
    end

    test "creates reference with summary and description (OpenAPI 3.1)" do
      data = %{
        "$ref" => "#/components/schemas/User",
        "summary" => "User reference",
        "description" => "Reference to User schema"
      }

      assert {:ok, ref} = Reference.new(data)
      assert ref.ref == "#/components/schemas/User"
      assert ref.summary == "User reference"
      assert ref.description == "Reference to User schema"
    end

    test "creates reference without $ref" do
      data = %{
        "summary" => "Missing ref"
      }

      assert {:ok, ref} = Reference.new(data)
      assert ref.ref == nil
    end

    test "returns error for non-map input" do
      assert {:error, msg} = Reference.new("not a map")
      assert msg =~ "must be a map"
    end

    test "returns error for nil input" do
      assert {:error, msg} = Reference.new(nil)
      assert msg =~ "must be a map"
    end

    test "returns error for integer input" do
      assert {:error, msg} = Reference.new(123)
      assert msg =~ "must be a map"
    end
  end

  describe "Reference.validate/2" do
    test "validates reference with valid $ref" do
      ref = %Reference{ref: "#/components/schemas/User"}

      assert :ok = Reference.validate(ref)
    end

    test "returns error when $ref is missing" do
      ref = %Reference{ref: nil}

      assert {:error, msg} = Reference.validate(ref)
      assert msg =~ "reference"
    end

    test "validates with custom context" do
      ref = %Reference{ref: "#/components/parameters/Id"}

      assert :ok = Reference.validate(ref, "paths./users.get.parameters[0]")
    end

    test "validates reference with summary" do
      ref = %Reference{
        ref: "#/components/schemas/User",
        summary: "User schema"
      }

      assert :ok = Reference.validate(ref)
    end

    test "validates reference with description" do
      ref = %Reference{
        ref: "#/components/schemas/User",
        description: "The user schema definition"
      }

      assert :ok = Reference.validate(ref)
    end
  end
end
