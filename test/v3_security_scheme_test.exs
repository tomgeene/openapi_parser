defmodule OpenapiParser.V3SecuritySchemeTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.SecurityScheme
  alias OpenapiParser.Spec.V3.OAuthFlows
  alias OpenapiParser.Spec.V3.OAuthFlow

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

  test "creates apiKey with cookie location (V3 feature)" do
    data = %{
      "type" => "apiKey",
      "name" => "session",
      "in" => "cookie"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.location == :cookie
  end

  test "creates http security scheme with basic" do
    data = %{
      "type" => "http",
      "scheme" => "basic"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :http
    assert scheme.scheme == "basic"
  end

  test "creates http security scheme with bearer" do
    data = %{
      "type" => "http",
      "scheme" => "bearer",
      "bearerFormat" => "JWT"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.scheme == "bearer"
    assert scheme.bearer_format == "JWT"
  end

  test "creates mutualTLS security scheme" do
    data = %{
      "type" => "mutualTLS",
      "description" => "Mutual TLS authentication"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :mutualTLS
    assert scheme.description == "Mutual TLS authentication"
  end

  test "creates oauth2 security scheme" do
    data = %{
      "type" => "oauth2",
      "flows" => %{
        "implicit" => %{
          "authorizationUrl" => "https://example.com/oauth/authorize",
          "scopes" => %{
            "read" => "Read access"
          }
        }
      }
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :oauth2
    assert %OAuthFlows{} = scheme.flows
  end

  test "creates openIdConnect security scheme" do
    data = %{
      "type" => "openIdConnect",
      "openIdConnectUrl" => "https://example.com/.well-known/openid-configuration"
    }

    assert {:ok, scheme} = SecurityScheme.new(data)
    assert scheme.type == :openIdConnect

    assert scheme.open_id_connect_url ==
             "https://example.com/.well-known/openid-configuration"
  end

  test "validates apiKey security scheme" do
    scheme = %SecurityScheme{
      type: :apiKey,
      name: "api_key",
      location: :header
    }

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "validates http security scheme" do
    scheme = %SecurityScheme{
      type: :http,
      scheme: "bearer"
    }

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "validates mutualTLS security scheme" do
    scheme = %SecurityScheme{type: :mutualTLS}

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "validates oauth2 security scheme" do
    flows = %OAuthFlows{
      implicit: %OAuthFlow{
        authorization_url: "https://example.com/oauth",
        scopes: %{}
      }
    }

    scheme = %SecurityScheme{
      type: :oauth2,
      flows: flows
    }

    assert :ok = SecurityScheme.validate(scheme)
  end

  test "validates openIdConnect security scheme" do
    scheme = %SecurityScheme{
      type: :openIdConnect,
      open_id_connect_url: "https://example.com/.well-known/openid-configuration"
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

  test "fails validation when http scheme is missing" do
    scheme = %SecurityScheme{type: :http}

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "scheme is required")
  end

  test "fails validation when oauth2 flows is missing" do
    scheme = %SecurityScheme{type: :oauth2}

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "flows is required")
  end

  test "fails validation when openIdConnect URL is missing" do
    scheme = %SecurityScheme{type: :openIdConnect}

    assert {:error, msg} = SecurityScheme.validate(scheme)
    assert String.contains?(msg, "openIdConnectUrl is required")
  end
end
