defmodule OpenapiParser.OperationsTest do
  use ExUnit.Case, async: true

  describe "V3.Operation" do
    alias OpenapiParser.Spec.V3.Operation
    alias OpenapiParser.Spec.V3.Responses
    alias OpenapiParser.Spec.V3.Response

    test "creates operation with minimal data" do
      data = %{
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert %Responses{} = operation.responses
    end

    test "creates operation with tags" do
      data = %{
        "tags" => ["users", "admin"],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.tags == ["users", "admin"]
    end

    test "creates operation with summary and description" do
      data = %{
        "summary" => "Get user",
        "description" => "Get user by ID",
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.summary == "Get user"
      assert operation.description == "Get user by ID"
    end

    test "creates operation with operationId" do
      data = %{
        "operationId" => "getUser",
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.operation_id == "getUser"
    end

    test "creates operation with parameters" do
      data = %{
        "parameters" => [
          %{"name" => "id", "in" => "path", "required" => true, "schema" => %{"type" => "string"}}
        ],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert length(operation.parameters) == 1
    end

    test "creates operation with request body" do
      data = %{
        "requestBody" => %{
          "content" => %{
            "application/json" => %{
              "schema" => %{"type" => "object"}
            }
          }
        },
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.request_body != nil
    end

    test "creates operation with deprecated flag" do
      data = %{
        "deprecated" => true,
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.deprecated == true
    end

    test "creates operation with security requirements" do
      data = %{
        "security" => [
          %{"api_key" => []}
        ],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert length(operation.security) == 1
    end

    test "validates operation with responses" do
      operation = %Operation{
        responses: %Responses{
          responses: %{
            "200" => %Response{description: "Success"}
          }
        }
      }

      assert :ok = Operation.validate(operation)
    end

    test "validates with custom context" do
      operation = %Operation{
        responses: %Responses{
          responses: %{
            "200" => %Response{description: "Success"}
          }
        }
      }

      assert :ok = Operation.validate(operation, "paths./users.get")
    end
  end

  describe "V2.Operation" do
    alias OpenapiParser.Spec.V2.Operation
    alias OpenapiParser.Spec.V2.Responses
    alias OpenapiParser.Spec.V2.Response

    test "creates operation with minimal data" do
      data = %{
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert %Responses{} = operation.responses
    end

    test "creates operation with tags" do
      data = %{
        "tags" => ["users", "admin"],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.tags == ["users", "admin"]
    end

    test "creates operation with summary and description" do
      data = %{
        "summary" => "Get user",
        "description" => "Get user by ID",
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.summary == "Get user"
      assert operation.description == "Get user by ID"
    end

    test "creates operation with operationId" do
      data = %{
        "operationId" => "getUser",
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.operation_id == "getUser"
    end

    test "creates operation with consumes and produces" do
      data = %{
        "consumes" => ["application/json"],
        "produces" => ["application/json", "application/xml"],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.consumes == ["application/json"]
      assert operation.produces == ["application/json", "application/xml"]
    end

    test "creates operation with parameters" do
      data = %{
        "parameters" => [
          %{"name" => "id", "in" => "path", "required" => true, "type" => "string"}
        ],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert length(operation.parameters) == 1
    end

    test "creates operation with schemes" do
      data = %{
        "schemes" => ["https", "http"],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.schemes == ["https", "http"]
    end

    test "creates operation with deprecated flag" do
      data = %{
        "deprecated" => true,
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert operation.deprecated == true
    end

    test "creates operation with security requirements" do
      data = %{
        "security" => [
          %{"api_key" => []}
        ],
        "responses" => %{
          "200" => %{"description" => "Success"}
        }
      }

      assert {:ok, operation} = Operation.new(data)
      assert length(operation.security) == 1
    end

    test "validates operation with responses" do
      operation = %Operation{
        responses: %Responses{
          responses: %{
            "200" => %Response{description: "Success"}
          }
        }
      }

      assert :ok = Operation.validate(operation)
    end

    test "validates with custom context" do
      operation = %Operation{
        responses: %Responses{
          responses: %{
            "200" => %Response{description: "Success"}
          }
        }
      }

      assert :ok = Operation.validate(operation, "paths./users.get")
    end
  end
end
