defmodule OpenapiParser.FinalCoveragePushTest do
  use ExUnit.Case, async: true

  # Focus on low-coverage modules to push above 90%

  # V3.Header tests for error paths
  describe "V3.Header error handling" do
    alias OpenapiParser.Spec.V3.Header

    test "validates deprecated header" do
      header = %Header{
        deprecated: true,
        schema: %OpenapiParser.Spec.V3.Schema{type: :string}
      }

      assert :ok = Header.validate(header)
    end

    test "validates header with allow_empty_value" do
      header = %Header{
        allow_empty_value: true,
        schema: %OpenapiParser.Spec.V3.Schema{type: :string}
      }

      assert :ok = Header.validate(header)
    end
  end

  # V3.Parameter additional edge cases
  describe "V3.Parameter edge cases" do
    alias OpenapiParser.Spec.V3.Parameter
    alias OpenapiParser.Spec.V3.Schema

    test "validates cookie parameter (V3 feature)" do
      param = %Parameter{
        name: "session",
        location: :cookie,
        required: false,
        schema: %Schema{type: :string}
      }

      assert :ok = Parameter.validate(param)
    end

    test "validates parameter with allowEmptyValue" do
      param = %Parameter{
        name: "filter",
        location: :query,
        allow_empty_value: true,
        schema: %Schema{type: :string}
      }

      assert :ok = Parameter.validate(param)
    end

    test "validates parameter with allowReserved" do
      param = %Parameter{
        name: "url",
        location: :query,
        allow_reserved: true,
        schema: %Schema{type: :string}
      }

      assert :ok = Parameter.validate(param)
    end
  end

  # V3.Link additional scenarios
  describe "V3.Link additional coverage" do
    alias OpenapiParser.Spec.V3.Link

    test "creates link with both operationId and operationRef is allowed" do
      data = %{
        "operationId" => "getUser",
        "operationRef" => "#/paths/~1users/get"
      }

      assert {:ok, link} = Link.new(data)
      assert link.operation_id == "getUser"
      assert link.operation_ref == "#/paths/~1users/get"
    end

    test "validates link with all fields" do
      link = %Link{
        operation_id: "getUser",
        parameters: %{"userId" => "$response.body#/id"},
        request_body: "$request.body",
        description: "Link to user",
        server: %OpenapiParser.Spec.V3.Server{url: "https://api.example.com"}
      }

      assert :ok = Link.validate(link)
    end
  end

  # V2 Parser additional tests
  describe "V2 Parser additional coverage" do
    alias OpenapiParser.Parser.V2

    test "parses V2 spec with all fields" do
      data = %{
        "swagger" => "2.0",
        "info" => %{
          "title" => "Test API",
          "version" => "1.0.0",
          "description" => "Test"
        },
        "host" => "api.example.com",
        "basePath" => "/v1",
        "schemes" => ["https"],
        "consumes" => ["application/json"],
        "produces" => ["application/json"],
        "paths" => %{},
        "definitions" => %{},
        "parameters" => %{},
        "responses" => %{},
        "securityDefinitions" => %{},
        "security" => [],
        "tags" => [],
        "externalDocs" => %{"url" => "https://docs.example.com"}
      }

      assert {:ok, spec} = V2.parse(data)
      assert spec.document.host == "api.example.com"
      assert spec.document.base_path == "/v1"
      assert spec.document.schemes == ["https"]
    end

    test "parses V2 spec with minimal required fields" do
      data = %{
        "swagger" => "2.0",
        "info" => %{
          "title" => "Test API",
          "version" => "1.0.0"
        },
        "paths" => %{}
      }

      assert {:ok, _spec} = V2.parse(data)
    end
  end

  # Additional Parser tests
  describe "Parser additional tests" do
    alias OpenapiParser.Parser

    test "parses spec with resolve_refs option" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {"title": "Test", "version": "1.0.0"},
        "paths": {}
      }
      """

      assert {:ok, _parsed} = Parser.parse(spec, format: :json, resolve_refs: true)
    end
  end

  # V2 Responses additional tests
  describe "V2.Responses additional coverage" do
    alias OpenapiParser.Spec.V2.Responses

    test "creates responses with all status code types" do
      data = %{
        "200" => %{"description" => "Success"},
        "201" => %{"description" => "Created"},
        "400" => %{"description" => "Bad Request"},
        "404" => %{"description" => "Not Found"},
        "500" => %{"description" => "Internal Server Error"},
        "default" => %{"description" => "Default response"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert map_size(responses.responses) == 6
    end
  end

  # V3 Responses additional tests
  describe "V3.Responses additional coverage" do
    alias OpenapiParser.Spec.V3.Responses

    test "creates responses with multiple pattern codes" do
      data = %{
        "1XX" => %{"description" => "Informational"},
        "2XX" => %{"description" => "Success"},
        "3XX" => %{"description" => "Redirection"},
        "4XX" => %{"description" => "Client Error"},
        "5XX" => %{"description" => "Server Error"}
      }

      assert {:ok, responses} = Responses.new(data)
      assert map_size(responses.responses) == 5
    end
  end

  # Additional edge case tests
  test "validates schema with read/write only" do
    alias OpenapiParser.Spec.V3.Schema

    schema = %Schema{
      type: :object,
      properties: %{
        "id" => %Schema{type: :string, read_only: true},
        "password" => %Schema{type: :string, write_only: true}
      }
    }

    assert :ok = Schema.validate(schema)
  end

  test "validates schema with format" do
    alias OpenapiParser.Spec.V3.Schema

    schema = %Schema{
      type: :string,
      format: "uuid"
    }

    assert :ok = Schema.validate(schema)
  end

  test "validates server with variables" do
    alias OpenapiParser.Spec.V3.Server
    alias OpenapiParser.Spec.V3.ServerVariable

    server = %Server{
      url: "https://{environment}.example.com",
      variables: %{
        "environment" => %ServerVariable{
          default: "production",
          enum: ["production", "staging"]
        }
      }
    }

    assert :ok = Server.validate(server)
  end

  test "validates OAuthFlow with all fields" do
    alias OpenapiParser.Spec.V3.OAuthFlow

    flow = %OAuthFlow{
      authorization_url: "https://example.com/oauth/authorize",
      token_url: "https://example.com/oauth/token",
      refresh_url: "https://example.com/oauth/refresh",
      scopes: %{
        "read" => "Read access",
        "write" => "Write access"
      }
    }

    assert :ok = OAuthFlow.validate(flow)
  end

  test "validates external documentation" do
    alias OpenapiParser.Spec.ExternalDocumentation

    docs = %ExternalDocumentation{
      url: "https://docs.example.com",
      description: "API Documentation"
    }

    assert :ok = ExternalDocumentation.validate(docs)
  end

  test "validates contact info" do
    alias OpenapiParser.Spec.Contact

    contact = %Contact{
      name: "API Support",
      url: "https://support.example.com",
      email: "support@example.com"
    }

    assert :ok = Contact.validate(contact)
  end

  test "validates tag" do
    alias OpenapiParser.Spec.Tag

    tag = %Tag{
      name: "users",
      description: "User operations",
      external_docs: %OpenapiParser.Spec.ExternalDocumentation{
        url: "https://docs.example.com/users"
      }
    }

    assert :ok = Tag.validate(tag)
  end
end
