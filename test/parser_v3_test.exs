defmodule OpenapiParser.Parser.V3Test do
  use ExUnit.Case, async: true

  alias OpenapiParser.Parser.V3
  alias OpenapiParser.Spec

  test "parses OpenAPI 3.0 spec" do
    data = %{
      "openapi" => "3.0.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "paths" => %{
        "/test" => %{
          "get" => %{
            "responses" => %{"200" => %{"description" => "OK"}}
          }
        }
      }
    }

    assert {:ok, %Spec.OpenAPI{version: :v3_0}} = V3.parse(data, :v3_0)
  end

  test "parses OpenAPI 3.1 spec" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "paths" => %{
        "/test" => %{
          "get" => %{
            "responses" => %{"200" => %{"description" => "OK"}}
          }
        }
      }
    }

    assert {:ok, %Spec.OpenAPI{version: :v3_1}} = V3.parse(data, :v3_1)
  end

  test "returns error when OpenAPI 3.0 parsing fails" do
    # Missing required info field
    data = %{
      "openapi" => "3.0.0"
    }

    assert {:error, _msg} = V3.parse(data, :v3_0)
  end

  test "returns error when OpenAPI 3.1 parsing fails" do
    # Missing required info field
    data = %{
      "openapi" => "3.1.0"
    }

    assert {:error, _msg} = V3.parse(data, :v3_1)
  end
end
