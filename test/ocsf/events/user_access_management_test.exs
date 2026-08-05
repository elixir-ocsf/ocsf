defmodule OCSF.Events.UserAccessManagementTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, Policy, Product, User}
  alias OCSF.Events.UserAccessManagement
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("user_access")

  @activities [assign_privileges: 1, revoke_privileges: 2]

  defp base_opts do
    [
      user: %User{uid: "u1"},
      privileges: ["admin"],
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    for {fun, activity} <- @activities do
      test "#{fun}/1 -> activity #{activity}" do
        assert {:ok, event} = UserAccessManagement.unquote(fun)(base_opts())
        assert event.class_uid == 3005
        assert event.category_uid == 3
        assert event.activity_id == unquote(activity)
        assert event.type_uid == 3005 * 100 + unquote(activity)
        assert event.privileges == ["admin"]
      end
    end
  end

  describe "required fields" do
    test "returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)

      assert {:error, %Error{reason: :missing, path: "user"}} =
               UserAccessManagement.assign_privileges(opts)
    end

    test "returns {:error, _} when privileges is missing" do
      opts = Keyword.delete(base_opts(), :privileges)

      assert {:error, %Error{reason: :missing, path: "privileges"}} =
               UserAccessManagement.assign_privileges(opts)
    end

    test "returns {:error, _} when privileges is an empty list" do
      opts = Keyword.put(base_opts(), :privileges, [])

      assert {:error, %Error{reason: :missing, path: "privileges"}} =
               UserAccessManagement.revoke_privileges(opts)
    end

    test "casts a plain map user to %OCSF.User{}" do
      opts = Keyword.put(base_opts(), :user, %{uid: "u9"})
      assert {:ok, event} = UserAccessManagement.assign_privileges(opts)
      assert %User{uid: "u9"} = event.user
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      opts = Keyword.put(base_opts(), :status, :Failure)
      assert {:ok, event} = UserAccessManagement.revoke_privileges(opts)
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} =
               UserAccessManagement.assign_privileges(Keyword.delete(base_opts(), :severity))

      assert event.severity_id == 1
    end

    test "passes optional actor through" do
      opts = Keyword.put(base_opts(), :actor, %Actor{user: %User{uid: "admin-1"}})
      assert {:ok, event} = UserAccessManagement.assign_privileges(opts)
      assert event.actor.user.uid == "admin-1"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} = UserAccessManagement.unquote(fun)(user: %{uid: "u1"}, privileges: ["x"])
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks user and privileges as required fields" do
      required = SchemaValidator.required_fields(@schema)
      assert "user" in required
      assert "privileges" in required
    end

    test "activity_id values match OCSF.Activity for class 3005" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3005) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3005) |> Enum.map(fn {_n, id} -> 3005 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3005, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves user and privileges" do
      {:ok, event} =
        UserAccessManagement.assign_privileges(
          user: %{uid: "u9"},
          privileges: ["read", "write"]
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.user == event.user
      assert reparsed.privileges == ["read", "write"]
      assert reparsed.class_uid == 3005
      assert reparsed.activity_id == 1
    end

    test "serialized map carries _name labels for class/activity" do
      {:ok, event} = UserAccessManagement.revoke_privileges(base_opts())
      map = OCSF.to_map(event)
      assert map[:class_name] == "User Access Management"
      assert map[:activity_name] == "Revoke Privileges"
      assert map[:privileges] == ["admin"]
    end
  end

  describe "redaction" do
    test "deny policy nils PII fields on the user but keeps privileges" do
      {:ok, event} =
        UserAccessManagement.assign_privileges(
          user: %{uid: "u1", email_addr: "jane@test.com"},
          privileges: ["admin"]
        )

      redacted = OCSF.redact(event, %Policy{deny: [:contact]})
      assert redacted.user.email_addr == nil
      assert redacted.user.uid == "u1"
      assert redacted.privileges == ["admin"]
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = UserAccessManagement.assign_privileges(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      opts = Keyword.put(base_opts(), :severity, :Nope)
      assert {:ok, event} = UserAccessManagement.assign_privileges(opts)
      assert event.severity_id == 0
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{uam_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :uam_fmt)
      assert {:ok, event} = UserAccessManagement.assign_privileges(opts)
      assert event.metadata.event_code == "user_access_management:assign_privileges"
    end
  end
end
