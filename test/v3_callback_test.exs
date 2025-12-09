defmodule OpenapiParser.V3CallbackTest do
  use ExUnit.Case, async: true

  alias OpenapiParser.Spec.V3.Callback

  test "creates callback with expressions" do
    data = %{
      "{$request.body#/callbackUrl}" => %{
        "post" => %{
          "responses" => %{"200" => %{"description" => "OK"}}
        }
      }
    }

    assert {:ok, callback} = Callback.new(data)
    assert map_size(callback.expressions) == 1
    assert Map.has_key?(callback.expressions, "{$request.body#/callbackUrl}")
  end

  test "creates callback with multiple expressions" do
    data = %{
      "onEvent" => %{
        "post" => %{"responses" => %{"200" => %{"description" => "OK"}}}
      },
      "onError" => %{
        "post" => %{"responses" => %{"500" => %{"description" => "Error"}}}
      }
    }

    assert {:ok, callback} = Callback.new(data)
    assert map_size(callback.expressions) == 2
  end

  test "creates empty callback" do
    data = %{}

    assert {:ok, callback} = Callback.new(data)
    assert map_size(callback.expressions) == 0
  end

  test "returns error when path item invalid" do
    data = %{
      "onEvent" => %{
        "post" => %{}
        # Missing required responses
      }
    }

    assert {:error, _msg} = Callback.new(data)
  end

  test "validates callback" do
    data = %{
      "onEvent" => %{
        "post" => %{"responses" => %{"200" => %{"description" => "OK"}}}
      }
    }

    assert {:ok, callback} = Callback.new(data)
    assert :ok = Callback.validate(callback)
  end

  test "validates callback with invalid path item" do
    data = %{
      "onEvent" => %{
        "post" => %{"responses" => %{"200" => %{"description" => "OK"}}}
      }
    }

    assert {:ok, _callback} = Callback.new(data)
    # Manually create invalid callback for validation test
    invalid_callback = %Callback{
      expressions: %{
        "onEvent" => %OpenapiParser.Spec.V3.PathItem{
          get: %OpenapiParser.Spec.V3.Operation{
            operation_id: "test",
            responses: %OpenapiParser.Spec.V3.Responses{responses: %{}}
            # Empty responses will fail validation
          }
        }
      }
    }

    assert {:error, _msg} = Callback.validate(invalid_callback)
  end
end
