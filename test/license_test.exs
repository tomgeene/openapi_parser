defmodule OpenapiParser.LicenseTest do
  use ExUnit.Case, async: true

  describe "V2.License new/1" do
    alias OpenapiParser.Spec.V2.License

    test "creates License with name only" do
      data = %{"name" => "MIT"}

      assert {:ok, license} = License.new(data)
      assert license.name == "MIT"
      assert license.url == nil
    end

    test "creates License with name and url" do
      data = %{
        "name" => "Apache 2.0",
        "url" => "https://www.apache.org/licenses/LICENSE-2.0"
      }

      assert {:ok, license} = License.new(data)
      assert license.name == "Apache 2.0"
      assert license.url == "https://www.apache.org/licenses/LICENSE-2.0"
    end

    test "handles empty data" do
      data = %{}

      assert {:ok, license} = License.new(data)
      assert license.name == nil
      assert license.url == nil
    end
  end

  describe "V2.License validate/2" do
    alias OpenapiParser.Spec.V2.License

    test "validates license with name only" do
      license = %License{name: "MIT"}

      assert :ok = License.validate(license)
    end

    test "validates license with name and valid url" do
      license = %License{
        name: "Apache 2.0",
        url: "https://www.apache.org/licenses/LICENSE-2.0"
      }

      assert :ok = License.validate(license)
    end

    test "fails validation when name is missing" do
      license = %License{name: nil}

      assert {:error, msg} = License.validate(license)
      assert String.contains?(msg, "Required field(s) missing")
      assert String.contains?(msg, "name")
    end

    test "fails validation with invalid url" do
      license = %License{
        name: "MIT",
        url: "not-a-valid-url"
      }

      assert {:error, msg} = License.validate(license)
      assert String.contains?(msg, "valid URL")
    end

    test "validates with custom context" do
      license = %License{name: nil}

      assert {:error, msg} = License.validate(license, "info.license")
      assert String.contains?(msg, "info.license")
    end

    test "accepts http and https URLs" do
      for url <- ["http://example.com", "https://example.com"] do
        license = %License{name: "Test", url: url}
        assert :ok = License.validate(license)
      end
    end
  end

  describe "V3.License new/1" do
    alias OpenapiParser.Spec.V3.License

    test "creates License with name only" do
      data = %{"name" => "MIT"}

      assert {:ok, license} = License.new(data)
      assert license.name == "MIT"
      assert license.url == nil
      assert license.identifier == nil
    end

    test "creates License with name and url" do
      data = %{
        "name" => "Apache 2.0",
        "url" => "https://www.apache.org/licenses/LICENSE-2.0"
      }

      assert {:ok, license} = License.new(data)
      assert license.name == "Apache 2.0"
      assert license.url == "https://www.apache.org/licenses/LICENSE-2.0"
      assert license.identifier == nil
    end

    test "creates License with SPDX identifier (V3.1 feature)" do
      data = %{
        "name" => "Apache 2.0",
        "identifier" => "Apache-2.0"
      }

      assert {:ok, license} = License.new(data)
      assert license.name == "Apache 2.0"
      assert license.identifier == "Apache-2.0"
    end

    test "creates License with all fields" do
      data = %{
        "name" => "Apache 2.0",
        "url" => "https://www.apache.org/licenses/LICENSE-2.0",
        "identifier" => "Apache-2.0"
      }

      assert {:ok, license} = License.new(data)
      assert license.name == "Apache 2.0"
      assert license.url == "https://www.apache.org/licenses/LICENSE-2.0"
      assert license.identifier == "Apache-2.0"
    end

    test "handles empty data" do
      data = %{}

      assert {:ok, license} = License.new(data)
      assert license.name == nil
      assert license.url == nil
      assert license.identifier == nil
    end
  end

  describe "V3.License validate/2" do
    alias OpenapiParser.Spec.V3.License

    test "validates license with name only" do
      license = %License{name: "MIT"}

      assert :ok = License.validate(license)
    end

    test "validates license with name and valid url" do
      license = %License{
        name: "Apache 2.0",
        url: "https://www.apache.org/licenses/LICENSE-2.0"
      }

      assert :ok = License.validate(license)
    end

    test "validates license with SPDX identifier" do
      license = %License{
        name: "Apache 2.0",
        identifier: "Apache-2.0"
      }

      assert :ok = License.validate(license)
    end

    test "validates license with all fields" do
      license = %License{
        name: "Apache 2.0",
        url: "https://www.apache.org/licenses/LICENSE-2.0",
        identifier: "Apache-2.0"
      }

      assert :ok = License.validate(license)
    end

    test "fails validation when name is missing" do
      license = %License{name: nil}

      assert {:error, msg} = License.validate(license)
      assert String.contains?(msg, "Required field(s) missing")
      assert String.contains?(msg, "name")
    end

    test "fails validation with invalid url" do
      license = %License{
        name: "MIT",
        url: "not-a-valid-url"
      }

      assert {:error, msg} = License.validate(license)
      assert String.contains?(msg, "valid URL")
    end

    test "validates with custom context" do
      license = %License{name: nil}

      assert {:error, msg} = License.validate(license, "info.license")
      assert String.contains?(msg, "info.license")
    end

    test "accepts http and https URLs" do
      for url <- ["http://example.com", "https://example.com"] do
        license = %License{name: "Test", url: url}
        assert :ok = License.validate(license)
      end
    end

    test "validates common SPDX identifiers" do
      identifiers = ["MIT", "Apache-2.0", "GPL-3.0", "BSD-3-Clause", "ISC"]

      for id <- identifiers do
        license = %License{name: "Test", identifier: id}
        assert :ok = License.validate(license)
      end
    end
  end
end
