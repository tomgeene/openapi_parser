defmodule OpenapiParser.V3LinkTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Link
  alias OpenapiParser.Spec.V3.Server

  describe "new/1" do
    test "creates Link with operationRef" do
      data = %{
        "operationRef" => "#/paths/~1users~1{userId}/get",
        "description" => "Get user by ID"
      }

      assert {:ok, link} = Link.new(data)
      assert link.operation_ref == "#/paths/~1users~1{userId}/get"
      assert link.description == "Get user by ID"
    end

    test "creates Link with operationId" do
      data = %{
        "operationId" => "getUserById",
        "parameters" => %{
          "userId" => "$response.body#/id"
        }
      }

      assert {:ok, link} = Link.new(data)
      assert link.operation_id == "getUserById"
      assert link.parameters == %{"userId" => "$response.body#/id"}
    end

    test "creates Link with requestBody" do
      data = %{
        "operationId" => "createUser",
        "requestBody" => %{"name" => "$response.body#/name"}
      }

      assert {:ok, link} = Link.new(data)
      assert link.request_body == %{"name" => "$response.body#/name"}
    end

    test "creates Link with server" do
      data = %{
        "operationId" => "getUser",
        "server" => %{
          "url" => "https://api.example.com"
        }
      }

      assert {:ok, link} = Link.new(data)
      assert %Server{} = link.server
      assert link.server.url == "https://api.example.com"
    end

    test "creates Link without server" do
      data = %{
        "operationId" => "getUser"
      }

      assert {:ok, link} = Link.new(data)
      assert link.server == nil
    end
  end

  describe "validate/2" do
    test "validates Link with operationRef" do
      link = %Link{operation_ref: "#/paths/~1users/get"}

      assert :ok = Link.validate(link)
    end

    test "validates Link with operationId" do
      link = %Link{operation_id: "getUsers"}

      assert :ok = Link.validate(link)
    end

    test "returns error when neither operationRef nor operationId" do
      link = %Link{}

      assert {:error, msg} = Link.validate(link)
      assert msg =~ "Either operationRef or operationId is required"
    end

    test "returns error when both operationRef and operationId present" do
      link = %Link{
        operation_ref: "#/paths/~1users/get",
        operation_id: "getUsers"
      }

      assert {:error, msg} = Link.validate(link)
      assert msg =~ "mutually exclusive"
    end

    test "validates with custom context" do
      link = %Link{operation_id: "test"}

      assert :ok = Link.validate(link, "responses.200.links.GetUser")
    end

    test "validates Link with server" do
      server = %Server{url: "https://api.example.com"}
      link = %Link{operation_id: "test", server: server}

      assert :ok = Link.validate(link)
    end

    test "validates Link with description" do
      link = %Link{operation_id: "test", description: "Test link"}

      assert :ok = Link.validate(link)
    end
  end
end
