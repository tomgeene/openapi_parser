defmodule OpenapiParser.AdditionalCoverageTest do
  use ExUnit.Case, async: true

  # Tests for Link
  describe "V3.Link" do
    alias OpenapiParser.Spec.V3.Link

    test "creates link with operation ref" do
      data = %{
        "operationRef" => "#/paths/~1users~1{id}/get"
      }

      assert {:ok, link} = Link.new(data)
      assert link.operation_ref == "#/paths/~1users~1{id}/get"
    end

    test "creates link with operation id" do
      data = %{
        "operationId" => "getUser"
      }

      assert {:ok, link} = Link.new(data)
      assert link.operation_id == "getUser"
    end

    test "creates link with parameters" do
      data = %{
        "operationId" => "getUser",
        "parameters" => %{"userId" => "$response.body#/id"}
      }

      assert {:ok, link} = Link.new(data)
      assert link.parameters == %{"userId" => "$response.body#/id"}
    end

    test "creates link with request body" do
      data = %{
        "operationId" => "createUser",
        "requestBody" => "$request.body"
      }

      assert {:ok, link} = Link.new(data)
      assert link.request_body == "$request.body"
    end

    test "creates link with description" do
      data = %{
        "operationId" => "getUser",
        "description" => "Link to user"
      }

      assert {:ok, link} = Link.new(data)
      assert link.description == "Link to user"
    end

    test "validates link" do
      link = %Link{operation_id: "getUser"}

      assert :ok = Link.validate(link)
    end
  end

  # Tests for Example
  describe "V3.Example" do
    alias OpenapiParser.Spec.V3.Example

    test "creates example with value" do
      data = %{
        "value" => %{"name" => "John", "age" => 30}
      }

      assert {:ok, example} = Example.new(data)
      assert example.value == %{"name" => "John", "age" => 30}
    end

    test "creates example with summary and description" do
      data = %{
        "summary" => "User example",
        "description" => "Example of a user object",
        "value" => %{"name" => "John"}
      }

      assert {:ok, example} = Example.new(data)
      assert example.summary == "User example"
      assert example.description == "Example of a user object"
    end

    test "creates example with external value" do
      data = %{
        "externalValue" => "https://example.com/examples/user.json"
      }

      assert {:ok, example} = Example.new(data)
      assert example.external_value == "https://example.com/examples/user.json"
    end

    test "validates example" do
      example = %Example{value: "test"}

      assert :ok = Example.validate(example)
    end
  end

  # Tests for Callback
  describe "V3.Callback" do
    alias OpenapiParser.Spec.V3.Callback

    test "creates callback with expressions" do
      data = %{
        "{$request.body#/callbackUrl}" => %{
          "post" => %{
            "responses" => %{
              "200" => %{"description" => "Success"}
            }
          }
        }
      }

      assert {:ok, callback} = Callback.new(data)
      assert is_map(callback.expressions)
    end

    test "validates callback" do
      callback = %Callback{expressions: %{}}

      assert :ok = Callback.validate(callback)
    end
  end

  # Tests for ServerVariable
  describe "V3.ServerVariable" do
    alias OpenapiParser.Spec.V3.ServerVariable

    test "creates server variable with default" do
      data = %{
        "default" => "production"
      }

      assert {:ok, var} = ServerVariable.new(data)
      assert var.default == "production"
    end

    test "creates server variable with enum" do
      data = %{
        "default" => "production",
        "enum" => ["production", "staging", "development"]
      }

      assert {:ok, var} = ServerVariable.new(data)
      assert var.enum == ["production", "staging", "development"]
    end

    test "creates server variable with description" do
      data = %{
        "default" => "production",
        "description" => "Environment"
      }

      assert {:ok, var} = ServerVariable.new(data)
      assert var.description == "Environment"
    end

    test "validates server variable" do
      var = %ServerVariable{default: "production"}

      assert :ok = ServerVariable.validate(var)
    end

    test "fails validation when default is missing" do
      var = %ServerVariable{default: nil}

      assert {:error, msg} = ServerVariable.validate(var)
      assert String.contains?(msg, "default")
    end
  end

  # Tests for MediaType
  describe "V3.MediaType" do
    alias OpenapiParser.Spec.V3.MediaType
    alias OpenapiParser.Spec.V3.Schema

    test "creates media type with schema" do
      data = %{
        "schema" => %{"type" => "object"}
      }

      assert {:ok, media_type} = MediaType.new(data)
      assert %Schema{} = media_type.schema
    end

    test "creates media type with example" do
      data = %{
        "example" => %{"name" => "John"}
      }

      assert {:ok, media_type} = MediaType.new(data)
      assert media_type.example == %{"name" => "John"}
    end

    test "creates media type with examples" do
      data = %{
        "examples" => %{
          "user1" => %{"value" => %{"name" => "John"}}
        }
      }

      assert {:ok, media_type} = MediaType.new(data)
      assert media_type.examples != nil
    end

    test "creates media type with encoding" do
      data = %{
        "schema" => %{"type" => "object"},
        "encoding" => %{
          "image" => %{"contentType" => "image/png"}
        }
      }

      assert {:ok, media_type} = MediaType.new(data)
      assert media_type.encoding != nil
    end

    test "validates media type" do
      media_type = %MediaType{schema: %Schema{type: :object}}

      assert :ok = MediaType.validate(media_type)
    end
  end

  # Tests for PathItem
  describe "V3.PathItem" do
    alias OpenapiParser.Spec.V3.PathItem
    alias OpenapiParser.Spec.V3.Operation

    test "creates path item with get operation" do
      data = %{
        "get" => %{
          "responses" => %{"200" => %{"description" => "Success"}}
        }
      }

      assert {:ok, path_item} = PathItem.new(data)
      assert %Operation{} = path_item.get
    end

    test "creates path item with all HTTP methods" do
      data = %{
        "get" => %{"responses" => %{}},
        "post" => %{"responses" => %{}},
        "put" => %{"responses" => %{}},
        "patch" => %{"responses" => %{}},
        "delete" => %{"responses" => %{}},
        "head" => %{"responses" => %{}},
        "options" => %{"responses" => %{}},
        "trace" => %{"responses" => %{}}
      }

      assert {:ok, path_item} = PathItem.new(data)
      assert %Operation{} = path_item.get
      assert %Operation{} = path_item.post
      assert %Operation{} = path_item.put
    end

    test "creates path item with parameters" do
      data = %{
        "parameters" => [
          %{"name" => "id", "in" => "path", "required" => true, "schema" => %{"type" => "string"}}
        ]
      }

      assert {:ok, path_item} = PathItem.new(data)
      assert length(path_item.parameters) == 1
    end

    test "validates path item" do
      path_item = %PathItem{}

      assert :ok = PathItem.validate(path_item)
    end
  end

  # Tests for V2.PathItem
  describe "V2.PathItem" do
    alias OpenapiParser.Spec.V2.PathItem
    alias OpenapiParser.Spec.V2.Operation

    test "creates path item with get operation" do
      data = %{
        "get" => %{
          "responses" => %{"200" => %{"description" => "Success"}}
        }
      }

      assert {:ok, path_item} = PathItem.new(data)
      assert %Operation{} = path_item.get
    end

    test "creates path item with all HTTP methods" do
      data = %{
        "get" => %{"responses" => %{}},
        "post" => %{"responses" => %{}},
        "put" => %{"responses" => %{}},
        "patch" => %{"responses" => %{}},
        "delete" => %{"responses" => %{}},
        "head" => %{"responses" => %{}},
        "options" => %{"responses" => %{}}
      }

      assert {:ok, path_item} = PathItem.new(data)
      assert %Operation{} = path_item.get
      assert %Operation{} = path_item.post
    end

    test "validates path item" do
      path_item = %PathItem{}

      assert :ok = PathItem.validate(path_item)
    end
  end
end
