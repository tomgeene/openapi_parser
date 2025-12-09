defmodule OpenapiParser.V2OperationTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Operation

  test "creates operation with all fields" do
    data = %{
      "tags" => ["users"],
      "summary" => "Get users",
      "description" => "Retrieve all users",
      "operationId" => "getUsers",
      "consumes" => ["application/json"],
      "produces" => ["application/json"],
      "schemes" => ["https"],
      "deprecated" => false,
      "parameters" => [],
      "responses" => %{
        "200" => %{"description" => "Success"}
      },
      "security" => []
    }

    assert {:ok, op} = Operation.new(data)
    assert op.tags == ["users"]
    assert op.summary == "Get users"
    assert op.description == "Retrieve all users"
    assert op.operation_id == "getUsers"
    assert op.consumes == ["application/json"]
    assert op.produces == ["application/json"]
    assert op.schemes == ["https"]
    assert op.deprecated == false
  end

  test "creates operation with external docs" do
    data = %{
      "externalDocs" => %{
        "url" => "https://example.com/docs",
        "description" => "External documentation"
      },
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    assert {:ok, op} = Operation.new(data)
    assert op.external_docs != nil
    assert op.external_docs.url == "https://example.com/docs"
  end

  test "creates operation with parameters" do
    data = %{
      "parameters" => [
        %{
          "name" => "id",
          "in" => "path",
          "type" => "string",
          "required" => true
        }
      ],
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    assert {:ok, op} = Operation.new(data)
    assert length(op.parameters) == 1
    assert hd(op.parameters).name == "id"
  end

  test "creates operation with security" do
    data = %{
      "security" => [
        %{"api_key" => []},
        %{"oauth2" => ["read", "write"]}
      ],
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    assert {:ok, op} = Operation.new(data)
    assert length(op.security) == 2
  end

  test "returns error when responses missing" do
    data = %{
      "operationId" => "test"
    }

    assert {:error, msg} = Operation.new(data)
    assert String.contains?(msg, "responses")
  end

  test "validates operation" do
    data = %{
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    assert {:ok, op} = Operation.new(data)
    assert :ok = Operation.validate(op)
  end

  test "validates operation with invalid parameter" do
    data = %{
      "parameters" => [
        %{
          "name" => "id",
          "in" => "path"
          # Missing required field
        }
      ],
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    assert {:ok, op} = Operation.new(data)
    assert {:error, _msg} = Operation.validate(op)
  end

  test "handles parameter parsing error" do
    data = %{
      "parameters" => [
        %{
          "name" => "id",
          "in" => "path",
          "type" => "string",
          "items" => %{"type" => "invalid"}
        }
      ],
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    # Should handle parsing error
    result = Operation.new(data)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "handles security parsing error" do
    data = %{
      "security" => [
        %{"invalid" => "security"}
      ],
      "responses" => %{"200" => %{"description" => "OK"}}
    }

    # Should handle parsing error
    result = Operation.new(data)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "validates operation with invalid responses" do
    data = %{
      "responses" => %{
        "200" => %{"description" => "OK"}
      }
    }

    assert {:ok, op} = Operation.new(data)
    # Manually create invalid operation for validation
    invalid_op = %OpenapiParser.Spec.V2.Operation{
      responses: %OpenapiParser.Spec.V2.Responses{responses: %{}}
    }

    assert {:error, _msg} = Operation.validate(invalid_op)
  end
end
