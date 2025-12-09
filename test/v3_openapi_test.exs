defmodule OpenapiParser.V3OpenAPITest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.OpenAPI

  test "creates OpenAPI with webhooks" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "webhooks" => %{
        "newPet" => %{
          "post" => %{
            "responses" => %{"200" => %{"description" => "OK"}}
          }
        }
      }
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert openapi.webhooks != nil
    assert Map.has_key?(openapi.webhooks, "newPet")
  end

  test "creates OpenAPI with only webhooks (3.1)" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "webhooks" => %{
        "test" => %{
          "post" => %{
            "responses" => %{"200" => %{"description" => "OK"}}
          }
        }
      }
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert openapi.paths == nil
    assert openapi.webhooks != nil
  end

  test "creates OpenAPI with only components (3.1)" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "components" => %{
        "schemas" => %{
          "Test" => %{"type" => "string"}
        }
      }
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert openapi.paths == nil
    assert openapi.components != nil
  end

  test "validates OpenAPI 3.1 with only webhooks" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "webhooks" => %{
        "test" => %{
          "post" => %{
            "responses" => %{"200" => %{"description" => "OK"}}
          }
        }
      }
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert :ok = OpenAPI.validate(openapi)
  end

  test "validates OpenAPI 3.1 with only components" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "components" => %{
        "schemas" => %{
          "Test" => %{"type" => "string"}
        }
      }
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert :ok = OpenAPI.validate(openapi)
  end

  test "returns error for OpenAPI 3.1 with no paths/components/webhooks" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"}
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert {:error, msg} = OpenAPI.validate(openapi)

    assert String.contains?(msg, "paths") || String.contains?(msg, "components") ||
             String.contains?(msg, "webhooks")
  end

  test "returns error for OpenAPI 3.0 with no paths" do
    data = %{
      "openapi" => "3.0.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"}
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert {:error, msg} = OpenAPI.validate(openapi)
    assert String.contains?(msg, "paths is required")
  end

  test "validates OpenAPI 3.0 with empty paths" do
    data = %{
      "openapi" => "3.0.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "paths" => %{}
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert :ok = OpenAPI.validate(openapi)
  end

  test "validates webhooks" do
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "webhooks" => %{
        "test" => %{
          "post" => %{
            "responses" => %{"200" => %{"description" => "OK"}}
          }
        }
      }
    }

    assert {:ok, openapi} = OpenAPI.new(data)
    assert :ok = OpenAPI.validate(openapi)
  end

  test "validates webhooks with invalid path item" do
    # This will fail during parsing, not validation
    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "webhooks" => %{
        "test" => %{
          "post" => %{}
          # Missing required responses - will fail during parsing
        }
      }
    }

    assert {:error, _msg} = OpenAPI.new(data)
  end
end
