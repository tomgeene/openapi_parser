defmodule OpenapiParser.MoreValidationTests do
  use ExUnit.Case, async: true

  # More validation edge cases
  test "validates deeply nested parameters" do
    alias OpenapiParser.Spec.V3.Parameter
    alias OpenapiParser.Spec.V3.Schema

    param = %Parameter{
      name: "filter",
      location: :query,
      required: false,
      schema: %Schema{
        type: :object,
        properties: %{
          "name" => %Schema{type: :string},
          "age" => %Schema{type: :integer}
        }
      }
    }

    assert :ok = Parameter.validate(param)
  end

  test "validates header with all style options" do
    alias OpenapiParser.Spec.V3.Header
    alias OpenapiParser.Spec.V3.Schema

    for style <- ["simple", "form", "matrix", "label"] do
      header = %Header{
        style: style,
        schema: %Schema{type: :string}
      }

      assert :ok = Header.validate(header)
    end
  end

  test "validates parameter with content" do
    alias OpenapiParser.Spec.V3.Parameter
    alias OpenapiParser.Spec.V3.MediaType
    alias OpenapiParser.Spec.V3.Schema

    param = %Parameter{
      name: "filter",
      location: :query,
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object}
        }
      }
    }

    assert :ok = Parameter.validate(param)
  end

  test "validates link with server" do
    alias OpenapiParser.Spec.V3.Link
    alias OpenapiParser.Spec.V3.Server

    link = %Link{
      operation_id: "getUser",
      server: %Server{
        url: "https://api.example.com"
      }
    }

    assert :ok = Link.validate(link)
  end

  test "validates encoding with all properties" do
    alias OpenapiParser.Spec.V3.Encoding

    encoding = %Encoding{
      content_type: "image/png",
      style: "form",
      explode: true,
      allow_reserved: false
    }

    assert :ok = Encoding.validate(encoding)
  end

  test "validates request body with all content types" do
    alias OpenapiParser.Spec.V3.RequestBody
    alias OpenapiParser.Spec.V3.MediaType
    alias OpenapiParser.Spec.V3.Schema

    request_body = %RequestBody{
      description: "User data",
      required: true,
      content: %{
        "application/json" => %MediaType{schema: %Schema{type: :object}},
        "application/xml" => %MediaType{schema: %Schema{type: :object}},
        "multipart/form-data" => %MediaType{schema: %Schema{type: :object}}
      }
    }

    assert :ok = RequestBody.validate(request_body)
  end

  test "validates response with headers" do
    alias OpenapiParser.Spec.V3.Response
    alias OpenapiParser.Spec.V3.Header
    alias OpenapiParser.Spec.V3.Schema

    response = %Response{
      description: "Success",
      headers: %{
        "X-Rate-Limit" => %Header{
          schema: %Schema{type: :integer}
        },
        "X-Rate-Reset" => %Header{
          schema: %Schema{type: :string}
        }
      }
    }

    assert :ok = Response.validate(response)
  end

  test "validates response with links" do
    alias OpenapiParser.Spec.V3.Response
    alias OpenapiParser.Spec.V3.Link

    response = %Response{
      description: "Success",
      links: %{
        "getUserOrders" => %Link{
          operation_id: "getOrders",
          parameters: %{"userId" => "$response.body#/id"}
        }
      }
    }

    assert :ok = Response.validate(response)
  end

  test "validates components with all component types" do
    alias OpenapiParser.Spec.V3.Components
    alias OpenapiParser.Spec.V3.Schema
    alias OpenapiParser.Spec.V3.Response
    alias OpenapiParser.Spec.V3.Parameter
    alias OpenapiParser.Spec.V3.RequestBody
    alias OpenapiParser.Spec.V3.SecurityScheme

    components = %Components{
      schemas: %{
        "User" => %Schema{type: :object}
      },
      responses: %{
        "NotFound" => %Response{description: "Not found"}
      },
      parameters: %{
        "UserId" => %Parameter{
          name: "id",
          location: :path,
          required: true,
          schema: %Schema{type: :string}
        }
      },
      request_bodies: %{
        "UserBody" => %RequestBody{
          description: "User",
          content: %{}
        }
      },
      security_schemes: %{
        "ApiKey" => %SecurityScheme{
          type: :apiKey,
          name: "api_key",
          location: :header
        }
      }
    }

    assert :ok = Components.validate(components)
  end

  test "validates discriminator with mapping" do
    alias OpenapiParser.Spec.V3.Discriminator

    discriminator = %Discriminator{
      property_name: "petType",
      mapping: %{
        "dog" => "#/components/schemas/Dog",
        "cat" => "#/components/schemas/Cat"
      }
    }

    assert :ok = Discriminator.validate(discriminator)
  end
end
