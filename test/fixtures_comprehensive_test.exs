defmodule OpenapiParserComprehensiveTest do
  use ExUnit.Case

  alias OpenapiParser.Spec

  describe "comprehensive YAML fixtures" do
    test "parses OpenAPI 3.1 comprehensive YAML" do
      assert {:ok, %Spec.OpenAPI{version: :v3_1, document: doc}} =
               OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")

      # Verify comprehensive features
      assert doc.info.title == "Comprehensive API Test"
      assert doc.info.version == "2.1.0"
      assert doc.info.contact.name == "API Team"
      assert doc.info.license.identifier == "Apache-2.0"

      # Verify servers with variables
      assert length(doc.servers) == 2
      [server1 | _] = doc.servers
      assert server1.variables != nil
      assert Map.has_key?(server1.variables, "environment")

      # Verify tags
      assert length(doc.tags) == 2

      # Verify paths
      assert map_size(doc.paths) > 0
      assert Map.has_key?(doc.paths, "/users")
      assert Map.has_key?(doc.paths, "/users/{userId}")

      # Verify components
      assert doc.components != nil
      assert map_size(doc.components.schemas) > 0
      assert Map.has_key?(doc.components.schemas, "User")
      assert Map.has_key?(doc.components.schemas, "Pet")

      # Verify security schemes
      assert map_size(doc.components.security_schemes) == 4
      assert Map.has_key?(doc.components.security_schemes, "OAuth2")
      assert Map.has_key?(doc.components.security_schemes, "BearerAuth")
    end

    test "parses OpenAPI 3.0 comprehensive YAML" do
      assert {:ok, %Spec.OpenAPI{version: :v3_0, document: doc}} =
               OpenapiParser.parse_file("test/fixtures/openapi_3.0_comprehensive.yaml")

      assert doc.info.title == "Comprehensive API Test - OpenAPI 3.0"
      assert length(doc.servers) == 2

      # Verify schema composition features
      path_item = Map.get(doc.paths, "/schema-tests/composition")
      assert path_item != nil
      assert path_item.post != nil
    end

    test "parses Swagger 2.0 comprehensive YAML" do
      assert {:ok, %Spec.OpenAPI{version: :v2, document: doc}} =
               OpenapiParser.parse_file("test/fixtures/swagger_2.0_comprehensive.yaml")

      assert doc.info.title == "Comprehensive API Test - Swagger 2.0"
      assert doc.host == "api.example.com"
      assert doc.base_path == "/v1"
      assert length(doc.schemes) == 2

      # Verify definitions
      assert map_size(doc.definitions) > 0
      assert Map.has_key?(doc.definitions, "Product")

      # Verify security definitions
      assert map_size(doc.security_definitions) == 3
    end
  end

  describe "edge cases and boundary values" do
    test "parses edge cases fixture" do
      assert {:ok, %Spec.OpenAPI{document: doc}} =
               OpenapiParser.parse_file("test/fixtures/edge_cases.json")

      # Verify all HTTP methods
      path_item = Map.get(doc.paths, "/all-methods")
      assert path_item.get != nil
      assert path_item.post != nil
      assert path_item.put != nil
      assert path_item.patch != nil
      assert path_item.delete != nil
      assert path_item.head != nil
      assert path_item.options != nil
      assert path_item.trace != nil

      # Verify status code patterns
      status_path = Map.get(doc.paths, "/status-codes")
      responses = status_path.get.responses.responses
      assert Map.has_key?(responses, "200")
      assert Map.has_key?(responses, "404")
      assert Map.has_key?(responses, "1XX")
      assert Map.has_key?(responses, "2XX")
      assert Map.has_key?(responses, "default")

      # Verify complex schemas exist
      assert Map.has_key?(doc.components.schemas, "ComplexComposition")
      assert Map.has_key?(doc.components.schemas, "AllFormats")
      assert Map.has_key?(doc.components.schemas, "NullableFields")
    end

    test "validates boundary values in schemas" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/edge_cases.json")

      # Verify deeply nested objects are parsed
      boundary_path = Map.get(spec.document.paths, "/boundary-values")
      schema = boundary_path.post.request_body.content["application/json"].schema
      assert schema.properties["deeplyNested"] != nil

      # Verify array boundaries
      assert schema.properties["emptyArray"].min_items == 0
      assert schema.properties["largeArray"].max_items == 10000
    end
  end

  describe "YAML format validation" do
    test "YAML files parse correctly" do
      yaml_files = [
        "test/fixtures/openapi_3.1_comprehensive.yaml",
        "test/fixtures/openapi_3.0_comprehensive.yaml",
        "test/fixtures/swagger_2.0_comprehensive.yaml"
      ]

      for file <- yaml_files do
        assert {:ok, _spec} = OpenapiParser.parse_file(file),
               "Failed to parse #{file}"
      end
    end
  end

  describe "comprehensive validation" do
    test "validates comprehensive 3.1 spec" do
      assert {:ok, _spec} =
               OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml",
                 validate: true
               )
    end

    test "validates comprehensive 3.0 spec" do
      assert {:ok, _spec} =
               OpenapiParser.parse_file("test/fixtures/openapi_3.0_comprehensive.yaml",
                 validate: true
               )
    end

    test "validates comprehensive 2.0 spec" do
      assert {:ok, _spec} =
               OpenapiParser.parse_file("test/fixtures/swagger_2.0_comprehensive.yaml",
                 validate: true
               )
    end

    test "validates edge cases spec" do
      assert {:ok, _spec} =
               OpenapiParser.parse_file("test/fixtures/edge_cases.json", validate: true)
    end
  end

  describe "specific feature testing" do
    test "parses discriminator correctly" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      pet_schema = spec.document.components.schemas["Pet"]

      assert pet_schema.one_of != nil
      assert pet_schema.discriminator != nil
      assert pet_schema.discriminator.property_name == "petType"
      assert map_size(pet_schema.discriminator.mapping) == 2
    end

    test "parses callbacks correctly" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      webhook_path = Map.get(spec.document.paths, "/webhooks")

      assert webhook_path.post.callbacks != nil
      assert Map.has_key?(webhook_path.post.callbacks, "onUserCreated")
    end

    test "parses links correctly" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      user_path = Map.get(spec.document.paths, "/users/{userId}")

      response = user_path.get.responses.responses["200"]
      assert response.links != nil
      assert Map.has_key?(response.links, "getUserOrders")
    end

    test "parses encoding for multipart" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      products_path = Map.get(spec.document.paths, "/products")

      content = products_path.post.request_body.content["multipart/form-data"]
      assert content.encoding != nil
      assert Map.has_key?(content.encoding, "image")
    end

    test "parses all security scheme types" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.1_comprehensive.yaml")
      schemes = spec.document.components.security_schemes

      assert schemes["ApiKeyAuth"].type == :apiKey
      assert schemes["BearerAuth"].type == :http
      assert schemes["OAuth2"].type == :oauth2
      assert schemes["OpenID"].type == :openIdConnect
    end

    test "parses nullable types in v3.0" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/openapi_3.0_comprehensive.yaml")
      item_schema = spec.document.components.schemas["Item"]

      # In OpenAPI 3.0, nullable is a separate property
      assert item_schema.properties["description"] != nil
    end

    test "parses file upload in swagger 2.0" do
      {:ok, spec} = OpenapiParser.parse_file("test/fixtures/swagger_2.0_comprehensive.yaml")
      upload_path = Map.get(spec.document.paths, "/upload")

      param = Enum.find(upload_path.post.parameters, fn p -> p.name == "file" end)
      assert param.type == :file
    end
  end
end
