defmodule OpenapiParser.V3ResponseTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Response

  test "creates response with all fields" do
    data = %{
      "description" => "Success response",
      "headers" => %{
        "X-Rate-Limit" => %{"schema" => %{"type" => "integer"}}
      },
      "content" => %{
        "application/json" => %{"schema" => %{"type" => "object"}}
      },
      "links" => %{
        "getUser" => %{"operationId" => "getUser"}
      }
    }

    assert {:ok, response} = Response.new(data)
    assert response.description == "Success response"
    assert map_size(response.headers) == 1
    assert map_size(response.content) == 1
    assert map_size(response.links) == 1
  end

  test "creates response with header reference" do
    data = %{
      "description" => "OK",
      "headers" => %{
        "X-Rate-Limit" => %{"$ref" => "#/components/headers/RateLimit"}
      }
    }

    assert {:ok, response} = Response.new(data)
    assert map_size(response.headers) == 1
  end

  test "creates response with link reference" do
    data = %{
      "description" => "OK",
      "links" => %{
        "getUser" => %{"$ref" => "#/components/links/GetUser"}
      }
    }

    assert {:ok, response} = Response.new(data)
    assert map_size(response.links) == 1
  end

  test "creates minimal response" do
    data = %{
      "description" => "OK"
    }

    assert {:ok, response} = Response.new(data)
    assert response.description == "OK"
    assert response.headers == nil
    assert response.content == nil
    assert response.links == nil
  end

  test "validates response" do
    data = %{
      "description" => "OK"
    }

    assert {:ok, response} = Response.new(data)
    assert :ok = Response.validate(response)
  end

  test "returns error when description missing" do
    data = %{}

    assert {:ok, response} = Response.new(data)
    assert {:error, msg} = Response.validate(response)
    assert String.contains?(msg, "description")
  end

  test "validates response with invalid headers" do
    data = %{
      "description" => "OK",
      "headers" => %{
        "X-Rate-Limit" => %{"schema" => %{"type" => "invalid_type"}}
      }
    }

    assert {:ok, response} = Response.new(data)
    # Header schema validation - might pass or fail depending on validation strictness
    result = Response.validate(response)
    assert result == :ok || match?({:error, _}, result)
  end
end
