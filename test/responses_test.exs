defmodule OpenapiParser.ResponsesTest do
  use ExUnit.Case, async: true

  describe "V3.Responses" do
    alias OpenapiParser.Spec.V3.Responses
    alias OpenapiParser.Spec.V3.Response

    test "creates Responses with status codes" do
      data = %{
        "200" => %{"description" => "Success"},
        "404" => %{"description" => "Not Found"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert map_size(responses.responses) == 2
      assert Map.has_key?(responses.responses, "200")
      assert Map.has_key?(responses.responses, "404")
    end

    test "creates Responses with default response" do
      data = %{
        "default" => %{"description" => "Error"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert Map.has_key?(responses.responses, "default")
    end

    test "creates Responses with pattern codes" do
      data = %{
        "2XX" => %{"description" => "Success"},
        "4XX" => %{"description" => "Client Error"},
        "5XX" => %{"description" => "Server Error"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert map_size(responses.responses) == 3
    end

    test "validates responses with at least one response" do
      responses = %Responses{
        responses: %{
          "200" => %Response{description: "Success"}
        }
      }

      assert :ok = Responses.validate(responses)
    end

    test "fails validation with no responses" do
      responses = %Responses{responses: %{}}

      assert {:error, msg} = Responses.validate(responses)
      assert String.contains?(msg, "At least one response")
    end
  end

  describe "V2.Responses" do
    alias OpenapiParser.Spec.V2.Responses
    alias OpenapiParser.Spec.V2.Response

    test "creates Responses with status codes" do
      data = %{
        "200" => %{"description" => "Success"},
        "404" => %{"description" => "Not Found"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert map_size(responses.responses) == 2
    end

    test "creates Responses with default response" do
      data = %{
        "default" => %{"description" => "Error"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert Map.has_key?(responses.responses, "default")
    end

    test "validates responses with at least one response" do
      responses = %Responses{
        responses: %{
          "200" => %Response{description: "Success"}
        }
      }

      assert :ok = Responses.validate(responses)
    end

    test "fails validation with no responses" do
      responses = %Responses{responses: %{}}

      assert {:error, msg} = Responses.validate(responses)
      assert String.contains?(msg, "At least one response")
    end
  end
end
