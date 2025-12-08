defmodule OpenapiParser.SecurityRequirementTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V2.SecurityRequirement, as: V2SecurityRequirement
  alias OpenapiParser.Spec.V3.SecurityRequirement, as: V3SecurityRequirement

  describe "V2.SecurityRequirement" do
    test "creates from valid map" do
      data = %{
        "api_key" => [],
        "oauth2" => ["read", "write"]
      }

      assert {:ok, req} = V2SecurityRequirement.new(data)
      assert req.requirements == data
    end

    test "returns error for non-map input" do
      assert {:error, msg} = V2SecurityRequirement.new("not a map")
      assert msg =~ "must be a map"
    end

    test "returns error for nil input" do
      assert {:error, msg} = V2SecurityRequirement.new(nil)
      assert msg =~ "must be a map"
    end

    test "returns error for list input" do
      assert {:error, msg} = V2SecurityRequirement.new(["invalid"])
      assert msg =~ "must be a map"
    end

    test "validates successfully" do
      req = %V2SecurityRequirement{requirements: %{"api_key" => []}}
      assert :ok = V2SecurityRequirement.validate(req)
    end

    test "validates with custom context" do
      req = %V2SecurityRequirement{requirements: %{}}
      assert :ok = V2SecurityRequirement.validate(req, "operation.security[0]")
    end
  end

  describe "V3.SecurityRequirement" do
    test "creates from valid map" do
      data = %{
        "petstore_auth" => ["write:pets", "read:pets"]
      }

      assert {:ok, req} = V3SecurityRequirement.new(data)
      assert req.requirements == data
    end

    test "creates with empty requirements" do
      data = %{}

      assert {:ok, req} = V3SecurityRequirement.new(data)
      assert req.requirements == %{}
    end

    test "returns error for non-map input" do
      assert {:error, msg} = V3SecurityRequirement.new("not a map")
      assert msg =~ "must be a map"
    end

    test "returns error for nil input" do
      assert {:error, msg} = V3SecurityRequirement.new(nil)
      assert msg =~ "must be a map"
    end

    test "returns error for integer input" do
      assert {:error, msg} = V3SecurityRequirement.new(123)
      assert msg =~ "must be a map"
    end

    test "validates successfully" do
      req = %V3SecurityRequirement{requirements: %{"oauth2" => ["scope1"]}}
      assert :ok = V3SecurityRequirement.validate(req)
    end

    test "validates with custom context" do
      req = %V3SecurityRequirement{requirements: %{}}
      assert :ok = V3SecurityRequirement.validate(req, "paths./pets.get.security[0]")
    end
  end
end
