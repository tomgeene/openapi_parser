defmodule OpenapiParser.V2SecuritySchemeTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.SecurityScheme

  test "creates basic security scheme" do
    data = %{"type" => "basic"}

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :basic
  end

  test "creates basic security scheme with description" do
    data = %{
      "type" => "basic",
      "description" => "HTTP Basic Authentication"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.description == "HTTP Basic Authentication"
  end

  test "creates apiKey security scheme" do
    data = %{
      "type" => "apiKey",
      "name" => "api_key",
      "in" => "header"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :apiKey
    assert scheme.name == "api_key"
    assert scheme.location == :header
  end

  test "creates apiKey with query location" do
    data = %{
      "type" => "apiKey",
      "name" => "api_key",
      "in" => "query"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.location == :query
  end

  test "creates oauth2 implicit flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "implicit",
      "authorizationUrl" => "https://example.com/oauth/authorize",
      "scopes" => %{
        "read" => "Read access",
        "write" => "Write access"
      }
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :oauth2
    assert scheme.flow == :implicit
    assert scheme.authorization_url == "https://example.com/oauth/authorize"
  end

  test "creates oauth2 password flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "password",
      "tokenUrl" => "https://example.com/oauth/token",
      "scopes" => %{}
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.flow == :password
    assert scheme.token_url == "https://example.com/oauth/token"
  end

  test "creates oauth2 application flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "application",
      "tokenUrl" => "https://example.com/oauth/token",
      "scopes" => %{}
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.flow == :application
  end

  test "creates oauth2 accessCode flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "accessCode",
      "authorizationUrl" => "https://example.com/oauth/authorize",
      "tokenUrl" => "https://example.com/oauth/token",
      "scopes" => %{}
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.flow == :accessCode
  end

  test "validates basic security scheme" do
    scheme = %SecurityScheme{type: :basic}

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "validates apiKey security scheme" do
    scheme = %SecurityScheme{
      type: :apiKey,
      name: "api_key",
      location: :header
    }

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "validates oauth2 security scheme" do
    scheme = %SecurityScheme{
      type: :oauth2,
      flow: :implicit,
      authorization_url: "https://example.com/oauth",
      scopes: %{}
    }

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "fails validation when type is missing" do
    scheme = %SecurityScheme{type: nil}

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "Required field(s) missing")
  end

  test "fails validation when apiKey name is missing" do
    scheme = %SecurityScheme{
      type: :apiKey,
      location: :header
    }

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "name is required")
  end

  test "fails validation when apiKey location is missing" do
    scheme = %SecurityScheme{
      type: :apiKey,
      name: "api_key"
    }

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "location")
  end

  test "fails validation when oauth2 flow is missing" do
    scheme = %SecurityScheme{type: :oauth2}

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "flow is required")
  end
end
