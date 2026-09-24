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

  describe "validate_event/2 attribute types and unknown attributes" do
    defp conformant_map do
      %{
        activity_id: 1,
        severity_id: 1,
        status_id: 1,
        category_uid: 3,
        class_uid: 3002,
        type_uid: 300_201,
        time: "2026-04-15T10:00:00Z",
        metadata: %{uid: "m1", version: "1.9.0", product: %{name: "Test"}},
        user: %{uid: "u1"},
        service: %{name: "svc"}
      }
    end

    test "accepts a conformant event" do
      assert {:ok, []} = SchemaValidator.validate_event(conformant_map(), @schema)
    end

    test "rejects attributes the class does not define" do
      event_map = Map.put(conformant_map(), :not_in_schema, 1)
      assert {:error, errors} = SchemaValidator.validate_event(event_map, @schema)
      assert "unknown attribute: not_in_schema" in errors
    end

    test "rejects a scalar where an object is expected" do
      event_map = Map.put(conformant_map(), :user, "u1")
      assert {:error, errors} = SchemaValidator.validate_event(event_map, @schema)
      assert Enum.any?(errors, &String.starts_with?(&1, "type mismatch: user must be an object"))
    end

    test "rejects a non-list where an array is expected" do
      schema = SchemaValidator.load_class_schema("role_management")

      event_map = %{
        activity_id: 6,
        severity_id: 1,
        category_uid: 3,
        class_uid: 3008,
        type_uid: 300_806,
        time: "2026-04-15T10:00:00Z",
        metadata: %{uid: "m1", version: "1.9.0", product: %{name: "Test"}},
        iam_role: %{uid: "r1"},
        resources: %{uid: "arn:1"}
      }

      assert {:error, errors} = SchemaValidator.validate_event(event_map, schema)

      assert Enum.any?(
               errors,
               &String.starts_with?(&1, "type mismatch: resources must be an array")
             )
    end

    test "checks each array element against the vendored object schema" do
      schema = SchemaValidator.load_class_schema("role_management")

      event_map = %{
        activity_id: 6,
        severity_id: 1,
        category_uid: 3,
        class_uid: 3008,
        type_uid: 300_806,
        time: "2026-04-15T10:00:00Z",
        metadata: %{uid: "m1", version: "1.9.0", product: %{name: "Test"}},
        iam_role: %{uid: "r1"},
        resources: ["arn:1", %{type: "bucket"}, %{uid: 42, bogus: true}]
      }

      assert {:error, errors} = SchemaValidator.validate_event(event_map, schema)

      assert Enum.any?(
               errors,
               &String.starts_with?(&1, "type mismatch: resources[0] must be an object")
             )

      assert Enum.any?(errors, &String.contains?(&1, "at least one of [\"name\", \"uid\"]"))
      assert Enum.any?(errors, &String.contains?(&1, "resources[1]"))

      assert Enum.any?(
               errors,
               &String.starts_with?(&1, "type mismatch: resources[2].uid must be")
             )

      assert "unknown attribute: resources[2].bogus" in errors
    end

    test "rejects wrong scalar types" do
      event_map =
        conformant_map()
        |> Map.put(:status_detail, 1)
        |> Map.put(:user, %{uid: "u1", has_mfa: "yes", type_id: "1"})

      assert {:error, errors} = SchemaValidator.validate_event(event_map, @schema)

      assert Enum.any?(
               errors,
               &String.starts_with?(&1, "type mismatch: status_detail must be string_t")
             )

      assert Enum.any?(
               errors,
               &String.starts_with?(&1, "type mismatch: user.has_mfa must be boolean_t")
             )

      assert Enum.any?(
               errors,
               &String.starts_with?(&1, "type mismatch: user.type_id must be integer_t")
             )
    end

    test "skips nil values and accepts json_t and epoch timestamps" do
      event_map =
        conformant_map()
        |> Map.put(:time, 1_776_000_000_000)
        |> Map.put(:status_detail, nil)
        |> Map.put(:unmapped, %{"anything" => [1, 2]})

      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
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
