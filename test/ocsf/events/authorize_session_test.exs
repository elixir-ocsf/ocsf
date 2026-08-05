defmodule OCSF.Events.AuthorizeSessionTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, Group, IamRole, Policy, Product, User}
  alias OCSF.Events.AuthorizeSession
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("authorize_session")

  @activities [assign_privileges: 1, assign_groups: 2]

  defp base_opts do
    [
      user: %User{uid: "u1"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    test "assign_privileges/1 -> activity 1" do
      opts = Keyword.put(base_opts(), :privileges, ["read:reports"])
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert event.class_uid == 3003
      assert event.category_uid == 3
      assert event.activity_id == 1
      assert event.type_uid == 300_301
      assert event.privileges == ["read:reports"]
    end

    test "assign_groups/1 -> activity 2 carries the group" do
      opts = Keyword.put(base_opts(), :group, %Group{uid: "g1", name: "Admins"})
      assert {:ok, event} = AuthorizeSession.assign_groups(opts)
      assert event.activity_id == 2
      assert event.type_uid == 300_302
      assert %Group{uid: "g1", name: "Admins"} = event.group
    end
  end

  describe "user requirement" do
    test "returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)

      assert {:error, %Error{reason: :missing, path: "user"}} =
               AuthorizeSession.assign_privileges(opts)
    end

    test "casts a plain map user to %OCSF.User{}" do
      opts = Keyword.put(base_opts(), :user, %{uid: "u9"})
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert %User{uid: "u9"} = event.user
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      opts = Keyword.put(base_opts(), :status, :Failure)
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} =
               AuthorizeSession.assign_privileges(Keyword.delete(base_opts(), :severity))

      assert event.severity_id == 1
    end

    test "passes optional actor through" do
      opts = Keyword.put(base_opts(), :actor, %Actor{user: %User{uid: "admin-1"}})
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert event.actor.user.uid == "admin-1"
    end

    test "casts and carries an optional iam_role, surviving a round-trip" do
      opts = Keyword.put(base_opts(), :iam_role, %{name: "admin", uid: "role-1"})
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert %IamRole{name: "admin", uid: "role-1"} = event.iam_role

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.iam_role == event.iam_role
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} = AuthorizeSession.unquote(fun)(user: %{uid: "u1"})
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks user as a required field" do
      assert "user" in SchemaValidator.required_fields(@schema)
    end

    test "activity_id values match OCSF.Activity for class 3003" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3003) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3003) |> Enum.map(fn {_n, id} -> 3003 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3003, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves user and privileges" do
      {:ok, event} =
        AuthorizeSession.assign_privileges(
          user: %{uid: "u9"},
          privileges: ["a", "b"],
          status: :Success
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.user == event.user
      assert reparsed.privileges == ["a", "b"]
      assert reparsed.class_uid == 3003
    end

    test "serialized map carries _name labels for class/activity" do
      opts = Keyword.put(base_opts(), :group, %Group{uid: "g1"})
      {:ok, event} = AuthorizeSession.assign_groups(opts)
      map = OCSF.to_map(event)
      assert map[:class_name] == "Authorize Session"
      assert map[:activity_name] == "Assign Groups"
    end

    test "empty privileges list is omitted from the serialized map" do
      {:ok, event} = AuthorizeSession.assign_privileges(Keyword.put(base_opts(), :privileges, []))
      refute Map.has_key?(OCSF.to_map(event), :privileges)
    end
  end

  describe "redaction" do
    test "deny policy nils PII fields on the user" do
      {:ok, event} =
        AuthorizeSession.assign_privileges(user: %{uid: "u1", email_addr: "jane@test.com"})

      redacted = OCSF.redact(event, %Policy{deny: [:contact]})
      assert redacted.user.email_addr == nil
      assert redacted.user.uid == "u1"
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      opts = Keyword.put(base_opts(), :severity, :Nope)
      assert {:ok, event} = AuthorizeSession.assign_privileges(opts)
      assert event.severity_id == 0
    end
  end

  describe "event_code_format integration" do
    test "applies default_format from config" do
      Application.put_env(:ocsf, :event_code,
        default_format: :auto_as,
        formats: %{auto_as: %{fields: [[:class_name], [:activity_name]], separator: "-"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      assert {:ok, event} = AuthorizeSession.assign_privileges(base_opts())
      assert event.metadata.event_code == "authorize_session-assign_privileges"
    end
  end
end
