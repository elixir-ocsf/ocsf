defmodule OCSF.Events.GroupManagementTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, Group, Policy, Product, Service, User}
  alias OCSF.Events.GroupManagement
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("group_management")

  @activities [
    assign_privileges: 1,
    revoke_privileges: 2,
    add_user: 3,
    remove_user: 4,
    delete: 5,
    create: 6,
    add_subgroup: 7,
    remove_subgroup: 8
  ]

  defp base_opts do
    [
      group: %Group{uid: "g1", name: "Admins", type: "role"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    for {fun, activity} <- @activities do
      test "#{fun}/1 -> activity #{activity}" do
        assert {:ok, event} = GroupManagement.unquote(fun)(base_opts())
        assert event.class_uid == 3006
        assert event.category_uid == 3
        assert event.activity_id == unquote(activity)
        assert event.type_uid == 3006 * 100 + unquote(activity)
      end
    end
  end

  describe "group requirement" do
    test "returns {:error, _} when group is missing" do
      opts = Keyword.delete(base_opts(), :group)
      assert {:error, %Error{reason: :missing, path: "group"}} = GroupManagement.create(opts)
    end

    test "casts a plain map group to %OCSF.Group{}" do
      opts = Keyword.put(base_opts(), :group, %{uid: "g2", name: "Eng", type: "team"})
      assert {:ok, event} = GroupManagement.create(opts)
      assert %Group{uid: "g2", name: "Eng", type: "team"} = event.group
    end

    test "carries the affected user on membership activities" do
      opts = Keyword.put(base_opts(), :user, %User{uid: "u1"})
      assert {:ok, event} = GroupManagement.add_user(opts)
      assert event.user.uid == "u1"
      assert event.group.uid == "g1"
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      assert {:ok, event} = GroupManagement.delete(Keyword.put(base_opts(), :status, :Failure))
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} = GroupManagement.create(Keyword.delete(base_opts(), :severity))
      assert event.severity_id == 1
    end

    test "integer severity and status pass through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = GroupManagement.create(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      assert {:ok, event} = GroupManagement.create(Keyword.put(base_opts(), :severity, :Nope))
      assert event.severity_id == 0
    end

    test "auto-generates metadata.uid and stamps version" do
      assert {:ok, event} = GroupManagement.create(base_opts())
      assert event.metadata.version == "1.8.0"
      assert byte_size(event.metadata.uid) > 0
    end

    test "auto-stamps correlation_uid from scope" do
      OCSF.Correlation.with("corr-gm-1", fn ->
        assert {:ok, event} = GroupManagement.add_user(base_opts())
        assert event.metadata.correlation_uid == "corr-gm-1"
      end)
    end

    test "accepts an %OCSF.Metadata{} struct and top-level shortcut keys" do
      opts =
        base_opts()
        |> Keyword.put(:metadata, %OCSF.Metadata{
          uid: "pre",
          version: "0.0.0",
          product: %Product{name: "Test"}
        })
        |> Keyword.put(:trace_uid, "t-1")
        |> Keyword.put(:span_uid, "s-1")
        |> Keyword.put(:event_code, "gm:create")
        |> Keyword.put(:unmapped, %{"k" => "v"})

      assert {:ok, event} = GroupManagement.create(opts)
      assert event.metadata.version == "1.8.0"
      assert event.metadata.trace_uid == "t-1"
      assert event.metadata.span_uid == "s-1"
      assert event.metadata.event_code == "gm:create"
      assert event.unmapped == %{"k" => "v"}
    end

    test "passes optional actor and service through" do
      opts =
        base_opts()
        |> Keyword.put(:actor, %Actor{user: %User{uid: "admin-1"}})
        |> Keyword.put(:service, %Service{name: "scim"})

      assert {:ok, event} = GroupManagement.create(opts)
      assert event.actor.user.uid == "admin-1"
      assert event.service.name == "scim"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} = GroupManagement.unquote(fun)(group: %{uid: "g1", name: "Admins"})
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks group as a required field" do
      assert "group" in SchemaValidator.required_fields(@schema)
    end

    test "activity_id values match OCSF.Activity for class 3006" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3006) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3006) |> Enum.map(fn {_n, id} -> 3006 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3006, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves the group" do
      {:ok, event} =
        GroupManagement.create(
          group: %{uid: "g9", name: "Admins", type: "role", desc: "admins"},
          status: :Success
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.group == event.group
      assert reparsed.class_uid == 3006
      assert reparsed.activity_id == 6
    end

    test "serialized map carries group with _name labels for class/activity" do
      {:ok, event} = GroupManagement.add_user(base_opts())
      map = OCSF.to_map(event)
      assert map[:group] == %{uid: "g1", name: "Admins", type: "role"}
      assert map[:class_name] == "Group Management"
      assert map[:activity_name] == "Add User"
    end
  end

  describe "redaction" do
    test "deny policy nils denied fields on the group" do
      {:ok, event} = GroupManagement.create(group: %{uid: "g1", name: "Admins", type: "role"})

      redacted = OCSF.redact(event, %Policy{deny: [:identifier]})

      assert redacted.group.uid == nil
      assert redacted.group.name == "Admins"
      assert redacted.group.type == "role"
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{gm_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :gm_fmt)
      assert {:ok, event} = GroupManagement.add_user(opts)
      assert event.metadata.event_code == "group_management:add_user"
    end

    test "applies default_format from config" do
      Application.put_env(:ocsf, :event_code,
        default_format: :auto_gm,
        formats: %{auto_gm: %{fields: [[:class_name], [:activity_name]], separator: "-"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      assert {:ok, event} = GroupManagement.create(base_opts())
      assert event.metadata.event_code == "group_management-create"
    end

    test "nonexistent format name leaves event_code nil" do
      opts = Keyword.put(base_opts(), :event_code_format, :nope)
      assert {:ok, event} = GroupManagement.create(opts)
      assert event.metadata.event_code == nil
    end
  end
end
