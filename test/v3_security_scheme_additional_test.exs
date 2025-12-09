defmodule OpenapiParser.V3SecuritySchemeAdditionalTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.SecurityScheme

  test "creates mutualTLS security scheme" do
    data = %{
      "type" => "mutualTLS",
      "description" => "Mutual TLS authentication"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :mutualTLS
    assert scheme.description == "Mutual TLS authentication"
  end

  test "creates http security scheme with bearer format" do
    data = %{
      "type" => "http",
      "scheme" => "bearer",
      "bearerFormat" => "JWT"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :http
    assert scheme.scheme == "bearer"
    assert scheme.bearer_format == "JWT"
  end

  test "validates mutualTLS security scheme" do
    data = %{
      "type" => "mutualTLS"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert :ok = SecurityScheme.validate(scheme)
  end

  test "returns error when apiKey missing name" do
    data = %{
      "type" => "apiKey",
      "in" => "header"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "name is required")
  end

  test "returns error when apiKey missing location" do
    data = %{
      "type" => "apiKey",
      "name" => "X-API-Key"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "in (location) is required")
  end

  test "returns error when http missing scheme" do
    data = %{
      "type" => "http"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "scheme is required")
  end

  test "returns error when oauth2 missing flows" do
    data = %{
      "type" => "oauth2"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "flows is required")
  end

  test "returns error when openIdConnect missing url" do
    data = %{
      "type" => "openIdConnect"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "openIdConnectUrl is required")
  end
end
