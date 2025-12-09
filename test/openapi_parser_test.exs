defmodule OpenapiParserTest do
  use ExUnit.Case
  doctest OpenapiParser

  alias OpenapiParser.Spec

  describe "parse/2" do
    test "parses OpenAPI 3.1 JSON" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        },
        "paths": {
          "/test": {
            "get": {
              "responses": {
                "200": {
                  "description": "OK"
                }
              }
            }
          }
        }
      }
      """

      assert {:ok, %Spec.OpenAPI{version: :v3_1}} = OpenapiParser.parse(spec, format: :json)
    end

    test "parses OpenAPI 3.0 JSON" do
      spec = """
      {
        "openapi": "3.0.0",
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        },
        "paths": {
          "/test": {
            "get": {
              "responses": {
                "200": {
                  "description": "OK"
                }
              }
            }
          }
        }
      }
      """

      assert {:ok, %Spec.OpenAPI{version: :v3_0}} = OpenapiParser.parse(spec, format: :json)
    end

    test "parses Swagger 2.0 JSON" do
      spec = """
      {
        "swagger": "2.0",
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        },
        "paths": {
          "/test": {
            "get": {
              "responses": {
                "200": {
                  "description": "OK"
                }
              }
            }
          }
        }
      }
      """

      assert {:ok, %Spec.OpenAPI{version: :v2}} = OpenapiParser.parse(spec, format: :json)
    end

    test "parses YAML format" do
      spec = """
      openapi: 3.1.0
      info:
        title: Test API
        version: 1.0.0
      paths:
        /test:
          get:
            responses:
              "200":
                description: OK
      """

      assert {:ok, %Spec.OpenAPI{version: :v3_1}} = OpenapiParser.parse(spec, format: :yaml)
    end

    test "validates required fields" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        }
      }
      """

      assert {:error, _} = OpenapiParser.parse(spec, format: :json, validate: true)
    end

    test "handles invalid JSON" do
      assert {:error, _} = OpenapiParser.parse("{ invalid json", format: :json)
    end

    test "handles missing version field" do
      spec = """
      {
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        },
        "paths": {}
      }
      """

      assert {:error, _} = OpenapiParser.parse(spec, format: :json)
    end
  end

  describe "parse_file/2" do
    test "parses OpenAPI 3.1 from file" do
      assert {:ok, %Spec.OpenAPI{version: :v3_1}} =
               OpenapiParser.parse_file("test/fixtures/openapi_3.1.json")
    end

    test "parses OpenAPI 3.0 from file" do
      assert {:ok, %Spec.OpenAPI{version: :v3_0}} =
               OpenapiParser.parse_file("test/fixtures/openapi_3.0.json")
    end

    test "parses Swagger 2.0 from file" do
      assert {:ok, %Spec.OpenAPI{version: :v2}} =
               OpenapiParser.parse_file("test/fixtures/swagger_2.0.json")
    end

    test "handles non-existent file" do
      assert {:error, _} = OpenapiParser.parse_file("test/fixtures/nonexistent.json")
    end
  end

  describe "validation" do
    test "validates path parameters are required" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        },
        "paths": {
          "/users/{id}": {
            "get": {
              "responses": {
                "200": {
                  "description": "OK"
                }
              },
              "parameters": [
                {
                  "name": "id",
                  "in": "path",
                  "required": false,
                  "schema": {
                    "type": "string"
                  }
                }
              ]
            }
          }
        }
      }
      """

      assert {:error, error_msg} = OpenapiParser.parse(spec, format: :json, validate: true)
      assert String.contains?(error_msg, "Path parameter must be required")
    end

    test "validates paths start with /" do
      spec = """
      {
        "openapi": "3.1.0",
        "info": {
          "title": "Test API",
          "version": "1.0.0"
        },
        "paths": {
          "invalid": {
            "get": {
              "responses": {
                "200": {
                  "description": "OK"
                }
              }
            }
          }
        }
      }
      """

      assert {:error, error_msg} = OpenapiParser.parse(spec, format: :json, validate: true)
      assert String.contains?(error_msg, "must start with")
    end
  end
end
