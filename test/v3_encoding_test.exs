defmodule OpenapiParser.V3EncodingTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Encoding
  alias OpenapiParser.Spec.V3.Header
  alias OpenapiParser.Spec.V3.Reference

  test "creates Encoding with minimal data" do
    data = %{}

    assert {:ok, encoding} = Encoding.new(data)
    assert encoding.content_type == nil
    assert encoding.headers == nil
  end

  test "creates Encoding with content type" do
    data = %{"contentType" => "application/json"}

    assert {:ok, encoding} = Encoding.new(data)
    assert encoding.content_type == "application/json"
  end

  test "creates Encoding with style and explode" do
    data = %{
      "style" => "form",
      "explode" => true,
      "allowReserved" => false
    }

    assert {:ok, encoding} = Encoding.new(data)
    assert encoding.style == "form"
    assert encoding.explode == true
    assert encoding.allow_reserved == false
  end

  test "creates Encoding with headers" do
    data = %{
      "headers" => %{
        "X-Rate-Limit" => %{
          "description" => "Rate limit",
          "schema" => %{"type" => "integer"}
        }
      }
    }

    assert {:ok, encoding} = Encoding.new(data)
    assert encoding.headers != nil
    assert Map.has_key?(encoding.headers, "X-Rate-Limit")
    assert %Header{} = encoding.headers["X-Rate-Limit"]
  end

  test "creates Encoding with header references" do
    data = %{
      "headers" => %{
        "X-Custom-Header" => %{
          "$ref" => "#/components/headers/CustomHeader"
        }
      }
    }

    assert {:ok, encoding} = Encoding.new(data)
    assert %Reference{} = encoding.headers["X-Custom-Header"]
  end

  test "validates minimal encoding" do
    encoding = %Encoding{}

    assert :ok = Encoding.validate(encoding)
  end

  test "validates encoding with all fields" do
    encoding = %Encoding{
      content_type: "application/json",
      style: "form",
      explode: true,
      allow_reserved: false
    }

    assert :ok = Encoding.validate(encoding)
  end

  test "validates with custom context" do
    encoding = %Encoding{}

    assert :ok = Encoding.validate(encoding, "requestBody.encoding")
  end

  test "creates Encoding with mixed headers and references" do
    data = %{
      "headers" => %{
        "X-Rate-Limit" => %{
          "description" => "Rate limit",
          "schema" => %{"type" => "integer"}
        },
        "X-Custom-Header" => %{
          "$ref" => "#/components/headers/CustomHeader"
        }
      }
    }

    assert {:ok, encoding} = Encoding.new(data)
    assert %Header{} = encoding.headers["X-Rate-Limit"]
    assert %Reference{} = encoding.headers["X-Custom-Header"]
  end

  test "validates encoding with headers" do
    encoding = %Encoding{
      headers: %{
        "X-Rate-Limit" => %Header{description: "Rate limit"}
      }
    }

    assert :ok = Encoding.validate(encoding)
  end

  test "validates encoding with header references" do
    encoding = %Encoding{
      headers: %{
        "X-Custom" => %Reference{ref: "#/components/headers/Custom"}
      }
    }

    assert :ok = Encoding.validate(encoding)
  end

  test "validates encoding with mixed headers" do
    encoding = %Encoding{
      headers: %{
        "X-Rate-Limit" => %Header{description: "Rate limit"},
        "X-Custom" => %Reference{ref: "#/components/headers/Custom"}
      }
    }

    assert :ok = Encoding.validate(encoding)
  end

  test "validates encoding types" do
    encoding = %Encoding{
      # invalid type
      content_type: 123,
      style: "form"
    }

    assert {:error, msg} = Encoding.validate(encoding)
    assert msg =~ "contentType"
  end
end
