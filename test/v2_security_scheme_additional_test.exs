defmodule OpenapiParser.V2SecuritySchemeAdditionalTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.SecurityScheme

  test "creates basic security scheme" do
    data = %{
      "type" => "basic",
      "description" => "HTTP Basic Authentication"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :basic
    assert scheme.description == "HTTP Basic Authentication"
  end

  test "creates oauth2 with implicit flow" do
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
    assert map_size(scheme.scopes) == 2
  end

  test "creates oauth2 with password flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "password",
      "tokenUrl" => "https://example.com/oauth/token",
      "scopes" => %{
        "read" => "Read access"
      }
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :oauth2
    assert scheme.flow == :password
    assert scheme.token_url == "https://example.com/oauth/token"
  end

  test "creates oauth2 with application flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "application",
      "tokenUrl" => "https://example.com/oauth/token",
      "scopes" => %{}
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :oauth2
    assert scheme.flow == :application
  end

  test "creates oauth2 with accessCode flow" do
    data = %{
      "type" => "oauth2",
      "flow" => "accessCode",
      "authorizationUrl" => "https://example.com/oauth/authorize",
      "tokenUrl" => "https://example.com/oauth/token",
      "scopes" => %{
        "read" => "Read access"
      }
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :oauth2
    assert scheme.flow == :accessCode
  end

  test "returns error when data is not a map" do
    assert {:error, msg} = SecurityScheme.new("not a map")
    assert String.contains?(msg, "must be a map")
  end

  test "validates basic security scheme" do
    data = %{
      "type" => "basic"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert :ok = SecurityScheme.validate(scheme)
  end

  test "returns error when oauth2 missing flow" do
    data = %{
      "type" => "oauth2"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "flow is required")
  end
end
