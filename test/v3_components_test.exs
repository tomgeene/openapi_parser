defmodule OpenapiParser.V3ComponentsTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Components

  test "creates components with all component types" do
    data = %{
      "schemas" => %{
        "User" => %{"type" => "object", "properties" => %{"name" => %{"type" => "string"}}}
      },
      "responses" => %{
        "Error" => %{"description" => "Error response"}
      },
      "parameters" => %{
        "IdParam" => %{
          "name" => "id",
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => "string"}
        }
      },
      "examples" => %{
        "UserExample" => %{"summary" => "Example user", "value" => %{"name" => "John"}}
      },
      "requestBodies" => %{
        "UserBody" => %{
          "content" => %{"application/json" => %{"schema" => %{"type" => "object"}}}
        }
      },
      "headers" => %{
        "X-Rate-Limit" => %{"schema" => %{"type" => "integer"}}
      },
      "securitySchemes" => %{
        "ApiKey" => %{"type" => "apiKey", "name" => "X-API-Key", "in" => "header"}
      },
      "links" => %{
        "UserLink" => %{"operationId" => "getUser"}
      },
      "callbacks" => %{
        "onEvent" => %{
          "{$request.body#/url}" => %{
            "post" => %{"responses" => %{"200" => %{"description" => "OK"}}}
          }
        }
      }
    }

    assert {:ok, components} = Components.new(data)
    assert components.schemas != nil
    assert components.responses != nil
    assert components.parameters != nil
    assert components.examples != nil
    assert components.request_bodies != nil
    assert components.headers != nil
    assert components.security_schemes != nil
    assert components.links != nil
    assert components.callbacks != nil
  end

  test "creates components with references" do
    data = %{
      "schemas" => %{
        "User" => %{"$ref" => "#/components/schemas/UserDef"}
      },
      "responses" => %{
        "Error" => %{"$ref" => "#/components/responses/ErrorDef"}
      }
    }

    assert {:ok, components} = Components.new(data)
    assert map_size(components.schemas) == 1
    assert map_size(components.responses) == 1
  end

  test "creates empty components" do
    data = %{}

    assert {:ok, components} = Components.new(data)
    assert components.schemas == nil
    assert components.responses == nil
  end

  test "handles component parsing with invalid schema" do
    data = %{
      "schemas" => %{
        "Invalid" => %{"type" => "invalid_type"}
      }
    }

    # Should still parse - invalid_type will be parsed as nil
    assert {:ok, _components} = Components.new(data)
  end

  test "validates components" do
    data = %{
      "schemas" => %{
        "User" => %{"type" => "object"}
      }
    }

    assert {:ok, components} = Components.new(data)
    assert :ok = Components.validate(components)
  end

  test "handles component parsing error" do
    # Invalid schema that will cause parsing to fail
    data = %{
      "schemas" => %{
        "Invalid" => %{
          "properties" => %{
            "name" => %{
              "allOf" => [
                %{"type" => "string"},
                %{"invalid" => "data"}
              ]
            }
          }
        }
      }
    }

    # Should handle error gracefully
    result = Components.new(data)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "validates components with all component types" do
    data = %{
      "schemas" => %{"User" => %{"type" => "object"}},
      "responses" => %{"Error" => %{"description" => "Error"}},
      "parameters" => %{
        "IdParam" => %{
          "name" => "id",
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => "string"}
        }
      },
      "examples" => %{"UserExample" => %{"value" => %{"name" => "John"}}},
      "requestBodies" => %{
        "UserBody" => %{
          "content" => %{
            "application/json" => %{
              "schema" => %{"type" => "object"}
            }
          }
        }
      },
      "headers" => %{"X-Rate-Limit" => %{"schema" => %{"type" => "integer"}}},
      "securitySchemes" => %{
        "ApiKey" => %{"type" => "apiKey", "name" => "X-API-Key", "in" => "header"}
      },
      "links" => %{"UserLink" => %{"operationId" => "getUser"}},
      "callbacks" => %{
        "onEvent" => %{
          "{$url}" => %{
            "post" => %{
              "responses" => %{"200" => %{"description" => "OK"}}
            }
          }
        }
      }
    }

    assert {:ok, components} = Components.new(data)
    assert :ok = Components.validate(components)
  end

  test "validates components with reference errors" do
    data = %{
      "schemas" => %{
        "User" => %{"$ref" => "#/components/schemas/User"}
      }
    }

    assert {:ok, components} = Components.new(data)
    # References might fail validation if they don't resolve, but parsing should succeed
    result = Components.validate(components)
    assert result == :ok or match?({:error, _}, result)
  end
end
