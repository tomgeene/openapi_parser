defmodule OpenapiParser.ParserCoverageTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Parser

  test "detects OpenAPI 3.1.x version" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:ok, parsed} = Parser.parse(spec, format: :json)
    assert parsed.version == :v3_1
  end

  test "detects OpenAPI 3.0.x version" do
    spec = """
    {
      "openapi": "3.0.3",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:ok, parsed} = Parser.parse(spec, format: :json)
    assert parsed.version == :v3_0
  end

  test "detects Swagger 2.0 version" do
    spec = """
    {
      "swagger": "2.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:ok, parsed} = Parser.parse(spec, format: :json)
    assert parsed.version == :v2
  end

  test "returns error for unsupported version" do
    spec = """
    {
      "openapi": "1.0.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:error, msg} = Parser.parse(spec, format: :json)
    assert String.contains?(msg, "Unsupported")
  end

  test "returns error when no version field present" do
    spec = """
    {
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:error, msg} = Parser.parse(spec, format: :json)
    assert String.contains?(msg, "version")
  end

  test "parses with validation disabled" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:ok, _parsed} = Parser.parse(spec, format: :json, validate: false)
  end

  test "parses with validation enabled" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {
        "/test": {
          "get": {
            "responses": {
              "200": {"description": "OK"}
            }
          }
        }
      }
    }
    """

    assert {:ok, _parsed} = Parser.parse(spec, format: :json, validate: true)
  end

  test "parses YAML format" do
    spec = """
    openapi: 3.1.0
    info:
      title: Test
      version: 1.0.0
    paths: {}
    """

    assert {:ok, parsed} = Parser.parse(spec, format: :yaml)
    assert parsed.version == :v3_1
  end

  test "auto-detects format" do
    json_spec = """
    {"openapi": "3.1.0", "info": {"title": "Test", "version": "1.0.0"}, "paths": {}}
    """

    assert {:ok, _parsed} = Parser.parse(json_spec, format: :auto)
  end

  test "handles parse errors gracefully" do
    invalid_json = "{invalid json}"

    assert {:error, _msg} = Parser.parse(invalid_json, format: :json)
  end

  test "Parser.V2 returns error when Swagger.new fails" do
    # Missing required 'info' field will cause V2.Swagger.new to fail
    spec = """
    {
      "swagger": "2.0",
      "paths": {}
    }
    """

    assert {:error, _msg} = Parser.parse(spec, format: :json)
  end

  test "Parser.V2 parses valid swagger spec" do
    alias OpenapiParser.Parser.V2

    data = %{
      "swagger" => "2.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "paths" => %{}
    }

    assert {:ok, spec} = V2.parse(data)
    assert spec.version == :v2
  end

  test "Parser.V3 parses valid openapi 3.0 spec" do
    alias OpenapiParser.Parser.V3

    data = %{
      "openapi" => "3.0.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "paths" => %{}
    }

    assert {:ok, spec} = V3.parse(data, :v3_0)
    assert spec.version == :v3_0
  end

  test "Parser.V3 parses valid openapi 3.1 spec" do
    alias OpenapiParser.Parser.V3

    data = %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Test", "version" => "1.0.0"},
      "paths" => %{}
    }

    assert {:ok, spec} = V3.parse(data, :v3_1)
    assert spec.version == :v3_1
  end

  test "handles JSON decode error with explicit format" do
    invalid_json = "{invalid json}"

    assert {:error, msg} = Parser.parse(invalid_json, format: :json)
    assert String.contains?(msg, "JSON decode error")
  end

  test "handles YAML decode error" do
    invalid_yaml = "invalid: yaml: [unclosed"

    assert {:error, msg} = Parser.parse(invalid_yaml, format: :yaml)
    assert String.contains?(msg, "YAML decode error")
  end

  test "handles file read error" do
    assert {:error, msg} = Parser.parse_file("nonexistent_file.json")
    assert String.contains?(msg, "Failed to read file")
  end

  test "detects format from file extension" do
    # Test .yaml extension
    assert {:ok, _} = Parser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
    # Test .json extension
    assert {:ok, _} = Parser.parse_file("test/fixtures/openapi_3.1.json")
  end

  test "handles unsupported Swagger version" do
    spec = """
    {
      "swagger": "1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {}
    }
    """

    assert {:error, msg} = Parser.parse(spec, format: :json)
    assert String.contains?(msg, "Unsupported Swagger version")
  end

  test "handles validation errors" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"}
    }
    """

    assert {:error, msg} = Parser.parse(spec, format: :json, validate: true)

    assert String.contains?(msg, "paths") || String.contains?(msg, "components") ||
             String.contains?(msg, "webhooks")
  end

  test "parses with resolve_refs option" do
    spec = """
    {
      "openapi": "3.1.0",
      "info": {"title": "Test", "version": "1.0.0"},
      "paths": {
        "/test": {
          "get": {
            "responses": {"200": {"description": "OK"}}
          }
        }
      }
    }
    """

    assert {:ok, _parsed} = Parser.parse(spec, format: :json, resolve_refs: true)
  end

  test "auto-detects YAML when JSON fails" do
    yaml_spec = """
    openapi: 3.1.0
    info:
      title: Test
      version: 1.0.0
    paths: {}
    """

    assert {:ok, parsed} = Parser.parse(yaml_spec, format: :auto)
    assert parsed.version == :v3_1
  end
end
