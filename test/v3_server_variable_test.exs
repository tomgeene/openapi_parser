defmodule OpenapiParser.V3ServerVariableTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.ServerVariable

  test "creates server variable with all fields" do
    data = %{
      "enum" => ["production", "staging", "development"],
      "default" => "production",
      "description" => "Server environment"
    }

    assert {:ok, var} = ServerVariable.new(data)
    assert var.enum == ["production", "staging", "development"]
    assert var.default == "production"
    assert var.description == "Server environment"
  end

  test "creates server variable with only default" do
    data = %{
      "default" => "production"
    }

    assert {:ok, var} = ServerVariable.new(data)
    assert var.default == "production"
    assert var.enum == nil
    assert var.description == nil
  end

  test "returns error when data is not a map" do
    assert {:error, msg} = ServerVariable.new("not a map")
    assert String.contains?(msg, "must be a map")
  end

  test "validates server variable" do
    data = %{
      "default" => "production"
    }

    assert {:ok, var} = ServerVariable.new(data)
    assert :ok = ServerVariable.validate(var)
  end

  test "validates default in enum" do
    data = %{
      "enum" => ["production", "staging"],
      "default" => "production"
    }

    assert {:ok, var} = ServerVariable.new(data)
    assert :ok = ServerVariable.validate(var)
  end

  test "returns error when default not in enum" do
    data = %{
      "enum" => ["production", "staging"],
      "default" => "development"
    }

    assert {:ok, var} = ServerVariable.new(data)
    assert {:error, msg} = ServerVariable.validate(var)
    assert String.contains?(msg, "must be one of the enum values")
  end

  test "returns error when default missing" do
    data = %{
      "enum" => ["production", "staging"]
    }

    assert {:ok, var} = ServerVariable.new(data)
    assert {:error, msg} = ServerVariable.validate(var)
    assert String.contains?(msg, "Required field")
  end
end
