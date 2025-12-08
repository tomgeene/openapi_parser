defmodule OpenapiParser.V3OperationTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Operation
  alias OpenapiParser.Spec.V3.Responses
  alias OpenapiParser.Spec.V3.Response
  alias OpenapiParser.Spec.V3.Parameter
  alias OpenapiParser.Spec.V3.Reference
  alias OpenapiParser.Spec.V3.RequestBody
  alias OpenapiParser.Spec.V3.Callback
  alias OpenapiParser.Spec.V3.SecurityRequirement
  alias OpenapiParser.Spec.V3.Server
  alias OpenapiParser.Spec.ExternalDocumentation

  describe "new/1" do
    test "creates operation with minimal data" do
      data = %{
        "responses" => %{
          "200" => %{"description" => "OK"}
        }
      }

      assert {:ok, op} = Operation.new(data)
      assert op.responses != nil
    end

    test "creates operation with tags and summary" do
      data = %{
        "tags" => ["users", "admin"],
        "summary" => "Get users",
        "description" => "Retrieves all users",
        "operationId" => "getUsers",
        "deprecated" => false,
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert op.tags == ["users", "admin"]
      assert op.summary == "Get users"
      assert op.description == "Retrieves all users"
      assert op.operation_id == "getUsers"
      assert op.deprecated == false
    end

    test "creates operation with externalDocs" do
      data = %{
        "externalDocs" => %{
          "url" => "https://docs.example.com",
          "description" => "Documentation"
        },
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert %ExternalDocumentation{} = op.external_docs
      assert op.external_docs.url == "https://docs.example.com"
    end

    test "creates operation with parameters" do
      data = %{
        "parameters" => [
          %{"name" => "id", "in" => "path", "required" => true}
        ],
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert length(op.parameters) == 1
      assert %Parameter{} = hd(op.parameters)
    end

    test "creates operation with parameter references" do
      data = %{
        "parameters" => [
          %{"$ref" => "#/components/parameters/UserIdParam"}
        ],
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert length(op.parameters) == 1
      assert %Reference{} = hd(op.parameters)
    end

    test "creates operation with requestBody" do
      data = %{
        "requestBody" => %{
          "content" => %{
            "application/json" => %{
              "schema" => %{"type" => "object"}
            }
          }
        },
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert %RequestBody{} = op.request_body
    end

    test "creates operation with requestBody reference" do
      data = %{
        "requestBody" => %{
          "$ref" => "#/components/requestBodies/CreateUser"
        },
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert %Reference{} = op.request_body
    end

    test "creates operation with callbacks" do
      data = %{
        "callbacks" => %{
          "onEvent" => %{
            "{$request.body#/callbackUrl}" => %{
              "post" => %{
                "responses" => %{"200" => %{"description" => "OK"}}
              }
            }
          }
        },
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert map_size(op.callbacks) == 1
      assert %Callback{} = op.callbacks["onEvent"]
    end

    test "creates operation with callback reference" do
      data = %{
        "callbacks" => %{
          "onEvent" => %{"$ref" => "#/components/callbacks/Event"}
        },
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert %Reference{} = op.callbacks["onEvent"]
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

    test "creates operation with servers" do
      data = %{
        "servers" => [
          %{"url" => "https://api.example.com"}
        ],
        "responses" => %{"200" => %{"description" => "OK"}}
      }

      assert {:ok, op} = Operation.new(data)
      assert length(op.servers) == 1
      assert %Server{} = hd(op.servers)
    end

    test "returns error when responses missing" do
      data = %{
        "operationId" => "test"
      }

      assert {:error, msg} = Operation.new(data)
      assert msg =~ "responses"
    end
  end

  describe "validate/2" do
    test "validates minimal operation" do
      op = %Operation{
        responses: %Responses{
          responses: %{
            "200" => %Response{description: "OK"}
          }
        }
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with external docs" do
      op = %Operation{
        external_docs: %ExternalDocumentation{url: "https://docs.example.com"},
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with parameters" do
      op = %Operation{
        parameters: [
          %Parameter{
            name: "id",
            location: :path,
            required: true,
            schema: %OpenapiParser.Spec.V3.Schema{type: :string}
          }
        ],
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with parameter references" do
      op = %Operation{
        parameters: [
          %Reference{ref: "#/components/parameters/Id"}
        ],
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with requestBody" do
      op = %Operation{
        request_body: %RequestBody{
          content: %{"application/json" => %OpenapiParser.Spec.V3.MediaType{}}
        },
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with requestBody reference" do
      op = %Operation{
        request_body: %Reference{ref: "#/components/requestBodies/Body"},
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with callbacks" do
      op = %Operation{
        callbacks: %{
          "onEvent" => %Callback{expressions: %{}}
        },
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with callback references" do
      op = %Operation{
        callbacks: %{
          "onEvent" => %Reference{ref: "#/components/callbacks/Event"}
        },
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with security" do
      op = %Operation{
        security: [%SecurityRequirement{requirements: %{"api_key" => []}}],
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates operation with servers" do
      op = %Operation{
        servers: [%Server{url: "https://api.example.com"}],
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op)
    end

    test "validates with custom context" do
      op = %Operation{
        responses: %Responses{responses: %{"200" => %Response{description: "OK"}}}
      }

      assert :ok = Operation.validate(op, "paths./users.get")
    end

    test "fails validation when responses is nil" do
      op = %Operation{responses: nil}

      # The validate function expects a Responses struct, so it will fail
      # when trying to call Responses.validate on nil
      assert_raise FunctionClauseError, fn ->
        Operation.validate(op)
      end
    end
  end
end
