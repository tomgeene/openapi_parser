defmodule OpenapiParser.ComprehensiveIntegrationTest do
  use ExUnit.Case, async: true

  # Integration tests that exercise multiple modules together

  test "full V3.1 spec parsing and validation" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {
        "title": "Comprehensive API",
        "version": "1.0.0",
        "description": "A comprehensive test API",
        "contact": {
          "name": "API Support",
          "email": "support@example.com",
          "url": "https://support.example.com"
        },
        "license": {
          "name": "MIT",
          "url": "https://opensource.org/licenses/MIT"
        }
      },
      "servers": [
        {
          "url": "https://{environment}.example.com/v1",
          "description": "API Server",
          "variables": {
            "environment": {
              "default": "production",
              "enum": ["production", "staging", "development"]
            }
          }
        }
      ],
      "paths": {
        "/users": {
          "get": {
            "summary": "List users",
            "description": "Get list of all users",
            "operationId": "listUsers",
            "tags": ["users"],
            "parameters": [
              {
                "name": "limit",
                "in": "query",
                "schema": {"type": "integer"},
                "description": "Max users to return"
              }
            ],
            "responses": {
              "200": {
                "description": "Success",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "array",
                      "items": {"$ref": "#/components/schemas/User"}
                    }
                  }
                }
              }
            }
          },
          "post": {
            "summary": "Create user",
            "operationId": "createUser",
            "tags": ["users"],
            "requestBody": {
              "required": true,
              "content": {
                "application/json": {
                  "schema": {"$ref": "#/components/schemas/User"}
                }
              }
            },
            "responses": {
              "201": {"description": "Created"}
            }
          }
        },
        "/users/{userId}": {
          "parameters": [
            {
              "name": "userId",
              "in": "path",
              "required": true,
              "schema": {"type": "string"}
            }
          ],
          "get": {
            "summary": "Get user",
            "operationId": "getUser",
            "tags": ["users"],
            "responses": {
              "200": {
                "description": "Success",
                "content": {
                  "application/json": {
                    "schema": {"$ref": "#/components/schemas/User"}
                  }
                }
              },
              "404": {"description": "Not found"}
            }
          }
        }
      },
      "components": {
        "schemas": {
          "User": {
            "type": "object",
            "required": ["name", "email"],
            "properties": {
              "id": {"type": "string", "readOnly": true},
              "name": {"type": "string"},
              "email": {"type": "string", "format": "email"},
              "age": {"type": "integer", "minimum": 0, "maximum": 150}
            }
          }
        },
        "securitySchemes": {
          "ApiKeyAuth": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key"
          },
          "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
          }
        }
      },
      "tags": [
        {
          "name": "users",
          "description": "User operations",
          "externalDocs": {
            "url": "https://docs.example.com/users",
            "description": "User documentation"
          }
        }
      ],
      "security": [
        {"ApiKeyAuth": []},
        {"BearerAuth": []}
      ]
    }
    """

    assert {:ok, parsed} = OpenapiParser.parse(spec, format: :json, validate: true)
    assert parsed.version == :v3_1
    assert parsed.document.info.title == "Comprehensive API"
    assert length(parsed.document.servers) == 1
    assert map_size(parsed.document.paths) == 2
  end

  test "full V2 spec parsing and validation" do
    spec = """
    {
      "swagger": "2.0",
      "info": {
        "title": "Comprehensive API V2",
        "version": "1.0.0",
        "description": "A comprehensive test API for Swagger 2.0",
        "contact": {
          "name": "API Support",
          "email": "support@example.com"
        },
        "license": {
          "name": "MIT",
          "url": "https://opensource.org/licenses/MIT"
        }
      },
      "host": "api.example.com",
      "basePath": "/v2",
      "schemes": ["https", "http"],
      "consumes": ["application/json"],
      "produces": ["application/json"],
      "paths": {
        "/users": {
          "get": {
            "summary": "List users",
            "description": "Get list of all users",
            "operationId": "listUsers",
            "tags": ["users"],
            "parameters": [
              {
                "name": "limit",
                "in": "query",
                "type": "integer",
                "description": "Max users to return"
              }
            ],
            "responses": {
              "200": {
                "description": "Success",
                "schema": {
                  "type": "array",
                  "items": {"$ref": "#/definitions/User"}
                }
              }
            }
          }
        },
        "/users/{userId}": {
          "parameters": [
            {
              "name": "userId",
              "in": "path",
              "required": true,
              "type": "string"
            }
          ],
          "get": {
            "summary": "Get user",
            "operationId": "getUser",
            "tags": ["users"],
            "responses": {
              "200": {
                "description": "Success",
                "schema": {"$ref": "#/definitions/User"}
              },
              "404": {"description": "Not found"}
            }
          }
        }
      },
      "definitions": {
        "User": {
          "type": "object",
          "required": ["name", "email"],
          "properties": {
            "id": {"type": "string"},
            "name": {"type": "string"},
            "email": {"type": "string", "format": "email"},
            "age": {"type": "integer", "minimum": 0, "maximum": 150}
          }
        }
      },
      "securityDefinitions": {
        "api_key": {
          "type": "apiKey",
          "name": "api_key",
          "in": "header"
        }
      },
      "tags": [
        {
          "name": "users",
          "description": "User operations"
        }
      ]
    }
    """

    assert {:ok, parsed} = OpenapiParser.parse(spec, format: :json, validate: true)
    assert parsed.version == :v2
    assert parsed.document.info.title == "Comprehensive API V2"
    assert parsed.document.host == "api.example.com"
    assert parsed.document.base_path == "/v2"
  end

  test "YAML parsing with complex structures" do
    spec = """
    openapi: 3.0.0
    info:
      title: YAML Test API
      version: 1.0.0
    paths:
      /test:
        get:
          summary: Test endpoint
          parameters:
            - name: filter
              in: query
              schema:
                type: object
                properties:
                  name:
                    type: string
                  age:
                    type: integer
          responses:
            '200':
              description: Success
              content:
                application/json:
                  schema:
                    type: object
                    properties:
                      data:
                        type: array
                        items:
                          type: string
    """

    assert {:ok, parsed} = OpenapiParser.parse(spec, format: :yaml, validate: true)
    assert parsed.version == :v3_0
  end

  test "error handling in complex spec" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {
        "invalid-path": {
          "get": {
            "responses": {
              "200": {"description": "OK"}
            }
          }
        }
      }
    }
    """

    # Should fail validation because path doesn't start with /
    assert {:error, msg} = OpenapiParser.parse(spec, format: :json, validate: true)
    assert String.contains?(msg, "must start with")
  end

  test "parsing with validation disabled accepts invalid spec" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {
        "invalid-path": {
          "get": {
            "responses": {}
          }
        }
      }
    }
    """

    # Should succeed without validation
    assert {:ok, _parsed} = OpenapiParser.parse(spec, format: :json, validate: false)
  end

  describe "JSON Schema 2020-12 features" do
    test "parses patternProperties" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["PatternPropertiesExample"]
      assert schema != nil
      assert map_size(schema.pattern_properties) == 3
      assert Map.has_key?(schema.pattern_properties, "^S_")
    end

    test "parses propertyNames" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["PropertyNamesExample"]
      assert schema != nil
      assert %OpenapiParser.Spec.V3.Schema{} = schema.property_names
    end

    test "parses prefixItems" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["PrefixItemsExample"]
      assert schema != nil
      assert length(schema.prefix_items) == 3
    end

    test "parses contains with minContains and maxContains" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["ContainsExample"]
      assert schema != nil
      assert schema.min_contains == 1
      assert schema.max_contains == 5
      assert %OpenapiParser.Spec.V3.Schema{} = schema.contains
    end

    test "parses unevaluatedItems" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["UnevaluatedItemsExample"]
      assert schema != nil
      assert schema.unevaluated_items == false
    end

    test "parses dependentSchemas" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["DependentSchemasExample"]
      assert schema != nil
      assert map_size(schema.dependent_schemas) == 1
      assert Map.has_key?(schema.dependent_schemas, "credit_card")
    end

    test "parses if/then/else" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["IfThenElseExample"]
      assert schema != nil
      assert %OpenapiParser.Spec.V3.Schema{} = schema.if_schema
      assert %OpenapiParser.Spec.V3.Schema{} = schema.then_schema
      assert %OpenapiParser.Spec.V3.Schema{} = schema.else_schema
    end

    test "parses $defs" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["DefsExample"]
      assert schema != nil
      assert map_size(schema.defs) == 2
    end

    test "parses $id, $anchor, $schema, $comment" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schema = spec.document.components.schemas["SchemaReferenceExample"]
      assert schema != nil
      assert schema.id == "https://example.com/schema"
      assert schema.anchor == "myAnchor"
      assert schema.schema_uri == "https://json-schema.org/draft/2020-12/schema"
      assert schema.comment == "This is a comment"
    end
  end

  describe "OpenAPI 3.1 specific features" do
    test "parses Info summary field" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")

      assert spec.document.info.summary ==
               "A comprehensive test covering all OpenAPI 3.1 features"
    end

    test "parses webhooks" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      assert spec.document.webhooks != nil
      assert Map.has_key?(spec.document.webhooks, "newPet")
      webhook = spec.document.webhooks["newPet"]
      assert webhook.post != nil
    end

    test "validates OpenAPI 3.1 with only webhooks" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {"title": "Test", "version": "1.0.0"},
        "webhooks": {
          "test": {
            "post": {
              "responses": {"200": {"description": "OK"}}
            }
          }
        }
      }
      """

      assert {:ok, parsed} = OpenapiParser.parse(spec, format: :json)
      assert parsed.document.webhooks != nil
    end

    test "validates OpenAPI 3.1 with only components" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {"title": "Test", "version": "1.0.0"},
        "components": {
          "schemas": {
            "Test": {"type": "string"}
          }
        }
      }
      """

      assert {:ok, parsed} = OpenapiParser.parse(spec, format: :json)
      assert parsed.document.components != nil
    end
  end

  describe "OpenAPI 3.0 nullable support" do
    test "parses nullable field" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.0_comprehensive.yaml")
      item_schema = spec.document.components.schemas["Item"]
      description_prop = item_schema.properties["description"]
      assert description_prop.nullable == true
    end
  end

  describe "Swagger 2.0 global objects" do
    test "parses global parameters" do
      spec = """
      {
        "swagger": "2.0",
        "info": {"title": "Test", "version": "1.0.0"},
        "paths": {},
        "parameters": {
          "GlobalLimitParam": {
            "name": "limit",
            "in": "query",
            "type": "integer"
          }
        }
      }
      """

      assert {:ok, parsed} = OpenapiParser.parse(spec, format: :json)
      assert parsed.document.parameters != nil
      assert Map.has_key?(parsed.document.parameters, "GlobalLimitParam")
    end

    test "parses global responses" do
      spec = """
      {
        "swagger": "2.0",
        "info": {"title": "Test", "version": "1.0.0"},
        "paths": {},
        "responses": {
          "GlobalError": {
            "description": "Error response",
            "schema": {"type": "object"}
          }
        }
      }
      """

      assert {:ok, parsed} = OpenapiParser.parse(spec, format: :json)
      assert parsed.document.responses != nil
      assert Map.has_key?(parsed.document.responses, "GlobalError")
    end
  end
end
