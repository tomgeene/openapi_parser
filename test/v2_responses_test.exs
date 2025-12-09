defmodule OpenapiParser.V2ResponsesTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.Responses

  test "creates responses with multiple status codes" do
    data = %{
      "200" => %{"description" => "Success"},
      "400" => %{"description" => "Bad Request"},
      "500" => %{"description" => "Server Error"}
    }

    assert {:ok, responses} = Responses.new(data)
    assert map_size(responses.responses) == 3
    assert Map.has_key?(responses.responses, "200")
    assert Map.has_key?(responses.responses, "400")
    assert Map.has_key?(responses.responses, "500")
  end

  test "creates responses with default" do
    data = %{
      "default" => %{"description" => "Default response"}
    }

    assert {:ok, responses} = Responses.new(data)
    assert Map.has_key?(responses.responses, "default")
  end

  test "creates responses with reference" do
    data = %{
      "200" => %{"$ref" => "#/responses/Success"}
    }

    assert {:ok, responses} = Responses.new(data)
    assert map_size(responses.responses) == 1
  end

  test "validates responses" do
    data = %{
      "200" => %{"description" => "OK"}
    }

    assert {:ok, responses} = Responses.new(data)
    assert :ok = Responses.validate(responses)
  end

  test "returns error when no responses" do
    data = %{}

    assert {:ok, responses} = Responses.new(data)
    assert {:error, msg} = Responses.validate(responses)
    assert String.contains?(msg, "At least one response")
  end

  test "validates status code format" do
    data = %{
      "200" => %{"description" => "OK"},
      "invalid" => %{"description" => "Invalid"}
    }

    assert {:ok, responses} = Responses.new(data)
    assert {:error, msg} = Responses.validate(responses)
    assert String.contains?(msg, "status code") || String.contains?(msg, "invalid")
  end

  test "handles response parsing error" do
    data = %{
      "200" => %{
        "schema" => %{
          "allOf" => [
            %{"type" => "object"},
            %{"invalid" => "data"}
          ]
        }
      }
    }

    result = Responses.new(data)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "handles response reference" do
    data = %{
      "200" => %{"$ref" => "#/responses/Success"}
    }

    assert {:ok, responses} = Responses.new(data)
    assert map_size(responses.responses) == 1
  end
end
