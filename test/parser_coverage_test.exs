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
end
