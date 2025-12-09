defmodule OpenapiParser.V3PathItemTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.PathItem

  test "creates path item with all HTTP methods" do
    data = %{
      "summary" => "User operations",
      "description" => "Operations on users",
      "get" => %{"responses" => %{"200" => %{"description" => "OK"}}},
      "post" => %{"responses" => %{"201" => %{"description" => "Created"}}},
      "put" => %{"responses" => %{"200" => %{"description" => "OK"}}},
      "delete" => %{"responses" => %{"204" => %{"description" => "No Content"}}},
      "options" => %{"responses" => %{"200" => %{"description" => "OK"}}},
      "head" => %{"responses" => %{"200" => %{"description" => "OK"}}},
      "patch" => %{"responses" => %{"200" => %{"description" => "OK"}}},
      "trace" => %{"responses" => %{"200" => %{"description" => "OK"}}}
    }

    assert {:ok, path_item} = PathItem.new(data)
    assert path_item.summary == "User operations"
    assert path_item.description == "Operations on users"
    assert path_item.get != nil
    assert path_item.post != nil
    assert path_item.put != nil
    assert path_item.delete != nil
    assert path_item.options != nil
    assert path_item.head != nil
    assert path_item.patch != nil
    assert path_item.trace != nil
  end

  test "creates path item with servers" do
    data = %{
      "servers" => [
        %{"url" => "https://api.example.com"},
        %{"url" => "https://staging.example.com"}
      ]
    }

    assert {:ok, path_item} = PathItem.new(data)
    assert length(path_item.servers) == 2
  end

  test "creates path item with parameters" do
    data = %{
      "parameters" => [
        %{
          "name" => "id",
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => "string"}
        }
      ]
    }

    assert {:ok, path_item} = PathItem.new(data)
    assert length(path_item.parameters) == 1
    assert hd(path_item.parameters).name == "id"
  end

  test "creates path item with parameter reference" do
    data = %{
      "parameters" => [
        %{"$ref" => "#/components/parameters/IdParam"}
      ]
    }

    assert {:ok, path_item} = PathItem.new(data)
    assert length(path_item.parameters) == 1
  end

  test "creates empty path item" do
    data = %{}

    assert {:ok, path_item} = PathItem.new(data)
    assert path_item.get == nil
    assert path_item.post == nil
  end

  test "validates path item" do
    data = %{
      "get" => %{"responses" => %{"200" => %{"description" => "OK"}}}
    }

    assert {:ok, path_item} = PathItem.new(data)
    assert :ok = PathItem.validate(path_item)
  end

  test "validates path item with invalid operation" do
    # This will fail during parsing, not validation
    data = %{
      "get" => %{
        "operationId" => "test"
        # Missing required responses - will fail during parsing
      }
    }

    assert {:error, _msg} = PathItem.new(data)
  end

  test "validates path item with invalid servers" do
    data = %{
      "servers" => [
        # Missing required url
        %{}
      ]
    }

    assert {:ok, path_item} = PathItem.new(data)
    assert {:error, _msg} = PathItem.validate(path_item)
  end
end
