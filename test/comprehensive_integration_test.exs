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
end
