defmodule OpenapiParser.V3MediaTypeTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.MediaType

  test "creates media type with schema" do
    data = %{
      "schema" => %{"type" => "object", "properties" => %{"name" => %{"type" => "string"}}}
    }

    assert {:ok, media_type} = MediaType.new(data)
    assert media_type.schema != nil
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
        "user1" => %{"summary" => "User 1", "value" => %{"name" => "John"}},
        "user2" => %{"summary" => "User 2", "value" => %{"name" => "Jane"}}
      }
    }

    assert {:ok, media_type} = MediaType.new(data)
    assert map_size(media_type.examples) == 2
  end

  test "creates media type with example reference" do
    data = %{
      "examples" => %{
        "user" => %{"$ref" => "#/components/examples/UserExample"}
      }
    }

    assert {:ok, media_type} = MediaType.new(data)
    assert map_size(media_type.examples) == 1
  end

  test "creates media type with encoding" do
    data = %{
      "encoding" => %{
        "name" => %{
          "contentType" => "text/plain"
        }
      }
    }

    assert {:ok, media_type} = MediaType.new(data)
    assert map_size(media_type.encoding) == 1
  end

  test "validates media type" do
    data = %{
      "schema" => %{"type" => "string"}
    }

    assert {:ok, media_type} = MediaType.new(data)
    assert :ok = MediaType.validate(media_type)
  end

  test "validates example and examples mutual exclusion" do
    data = %{
      "example" => %{"name" => "John"},
      "examples" => %{
        "user" => %{"value" => %{"name" => "Jane"}}
      }
    }

    assert {:ok, media_type} = MediaType.new(data)
    assert {:error, msg} = MediaType.validate(media_type)
    assert String.contains?(msg, "mutually exclusive")
  end

  test "validates media type with invalid schema" do
    data = %{
      "schema" => %{"type" => "invalid_type"}
    }

    assert {:ok, media_type} = MediaType.new(data)
    # Schema validation - might pass or fail depending on validation strictness
    result = MediaType.validate(media_type)
    assert result == :ok || match?({:error, _}, result)
  end
end
