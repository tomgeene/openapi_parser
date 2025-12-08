defmodule OpenapiParser.ReferenceResolverTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.ReferenceResolver
  alias OpenapiParser.Spec

  describe "resolve/1" do
    test "returns spec as-is for now" do
      spec = %Spec.OpenAPI{
        version: :v3_1,
        document: %OpenapiParser.Spec.V3.OpenAPI{
          openapi: "3.1.0",
          info: %OpenapiParser.Spec.Info{
            title: "Test API",
            version: "1.0.0"
          },
          paths: %{}
        }
      }

      assert {:ok, returned_spec} = ReferenceResolver.resolve(spec)
      assert returned_spec == spec
    end

    test "handles V2 spec" do
      spec = %Spec.OpenAPI{
        version: :v2,
        document: %OpenapiParser.Spec.V2.Swagger{
          swagger: "2.0",
          info: %OpenapiParser.Spec.Info{
            title: "Test API",
            version: "1.0.0"
          },
          paths: %{}
        }
      }

      assert {:ok, returned_spec} = ReferenceResolver.resolve(spec)
      assert returned_spec == spec
    end

    test "handles V3.0 spec" do
      spec = %Spec.OpenAPI{
        version: :v3_0,
        document: %OpenapiParser.Spec.V3.OpenAPI{
          openapi: "3.0.0",
          info: %OpenapiParser.Spec.Info{
            title: "Test API",
            version: "1.0.0"
          },
          paths: %{}
        }
      }

      assert {:ok, returned_spec} = ReferenceResolver.resolve(spec)
      assert returned_spec == spec
    end
  end
end
