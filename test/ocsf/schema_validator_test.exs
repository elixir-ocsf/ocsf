defmodule OCSF.Test.SchemaValidatorTest do
  use ExUnit.Case, async: true

  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("authentication")

  describe "enum_values/2" do
    test "returns empty MapSet for nonexistent attribute" do
      assert MapSet.equal?(SchemaValidator.enum_values(@schema, "nonexistent"), MapSet.new())
    end
  end

  describe "validate_event/2" do
    test "detects missing required fields" do
      assert {:error, errors} = SchemaValidator.validate_event(%{}, @schema)
      assert Enum.any?(errors, &String.contains?(&1, "missing required field"))
    end

    test "detects invalid enum values" do
      event_map = %{
        activity_id: 999,
        severity_id: 1,
        status_id: 1,
        category_uid: 3,
        class_uid: 3002,
        type_uid: 300_201,
        time: "2026-04-15T10:00:00Z",
        metadata: %{},
        user: %{uid: "u1"}
      }

      assert {:error, errors} = SchemaValidator.validate_event(event_map, @schema)
      assert Enum.any?(errors, &String.contains?(&1, "invalid activity_id"))
    end

    test "detects invalid type_uid" do
      event_map = %{
        activity_id: 1,
        severity_id: 1,
        status_id: 1,
        category_uid: 3,
        class_uid: 3002,
        type_uid: 999_999,
        time: "2026-04-15T10:00:00Z",
        metadata: %{},
        user: %{uid: "u1"},
        service: %{name: "svc"}
      }

      assert {:error, errors} = SchemaValidator.validate_event(event_map, @schema)
      assert Enum.any?(errors, &String.contains?(&1, "invalid type_uid"))
    end

    test "detects missing type_uid" do
      event_map = %{
        activity_id: 1,
        severity_id: 1,
        category_uid: 3,
        class_uid: 3002,
        time: "2026-04-15T10:00:00Z",
        metadata: %{},
        user: %{uid: "u1"},
        service: %{name: "svc"}
      }

      assert {:error, errors} = SchemaValidator.validate_event(event_map, @schema)
      assert Enum.any?(errors, &String.contains?(&1, "type_uid"))
    end

    test "handles schema without constraints" do
      schema_no_constraints = Map.delete(@schema, "constraints")

      event_map = %{
        activity_id: 1,
        severity_id: 1,
        status_id: 1,
        category_uid: 3,
        class_uid: 3002,
        type_uid: 300_201,
        time: "2026-04-15T10:00:00Z",
        metadata: %{},
        user: %{uid: "u1"}
      }

      assert {:ok, []} = SchemaValidator.validate_event(event_map, schema_no_constraints)
    end

    test "skips enum check for nil values" do
      event_map = %{
        activity_id: 1,
        severity_id: 1,
        status_id: 1,
        auth_protocol_id: nil,
        category_uid: 3,
        class_uid: 3002,
        type_uid: 300_201,
        time: "2026-04-15T10:00:00Z",
        metadata: %{},
        user: %{uid: "u1"},
        service: %{name: "svc"}
      }

      assert {:ok, []} = SchemaValidator.validate_event(event_map, schema_no_constraints())
    end
  end

  describe "required_fields/1" do
    test "excludes profile-only required fields" do
      required = SchemaValidator.required_fields(@schema)
      # "cloud" and "osint" are required but profile-only
      refute "cloud" in required
      refute "osint" in required
    end
  end

  defp schema_no_constraints do
    Map.delete(@schema, "constraints")
  end
end
