defmodule OCSF.Events.UserManagementTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, IamRole, Policy, Product, Service, User}
  alias OCSF.Events.UserManagement
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("user_management")

  @activities [
    create: 1,
    update: 2,
    delete: 3,
    enable: 4,
    disable: 5,
    lock: 6,
    unlock: 7,
    password_change: 8,
    password_reset: 9,
    attach_policies: 10,
    detach_policies: 11,
    enable_mfa_factors: 12,
    disable_mfa_factors: 13,
    assign_privileges: 14,
    remove_privileges: 15,
    assign_roles: 16,
    remove_roles: 17,
    add_programmatic_credentials: 18,
    remove_programmatic_credentials: 19
  ]

  defp base_opts do
    [
      user: %User{uid: "u1", name: "Jane"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    for {fun, activity} <- @activities do
      test "#{fun}/1 -> activity #{activity}" do
        assert {:ok, event} = UserManagement.unquote(fun)(base_opts())
        assert event.class_uid == 3007
        assert event.category_uid == 3
        assert event.activity_id == unquote(activity)
        assert event.type_uid == 3007 * 100 + unquote(activity)
      end
    end

    test "exposes one builder per OCSF.Activity entry for class 3007" do
      ids = Enum.map(@activities, fn {_fun, id} -> id end)
      # 19 real activities plus Unknown (0) and Other (99)
      assert length(ids) == 19

      schema_ids =
        OCSF.Activity.values(3007)
        |> Enum.map(fn {_n, id} -> id end)
        |> Enum.reject(&(&1 in [0, 99]))

      assert Enum.sort(ids) == Enum.sort(schema_ids)
    end
  end

  describe "user requirement" do
    test "returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)
      assert {:error, %Error{reason: :missing, path: "user"}} = UserManagement.create(opts)
    end

    test "casts a plain map user to %OCSF.User{}" do
      opts = Keyword.put(base_opts(), :user, %{uid: "u9", name: "Ada"})
      assert {:ok, event} = UserManagement.update(opts)
      assert %User{uid: "u9", name: "Ada"} = event.user
    end
  end

  describe "role, privilege, and updated_user attributes" do
    test "casts iam_roles list to %OCSF.IamRole{} structs" do
      opts =
        base_opts()
        |> Keyword.put(:iam_roles, [
          %{name: "admin", uid: "role-1"},
          %IamRole{name: "auditor", uid: "role-2"}
        ])

      assert {:ok, event} = UserManagement.assign_roles(opts)
      assert [%IamRole{name: "admin", uid: "role-1"}, %IamRole{name: "auditor"}] = event.iam_roles
    end

    test "casts updated_user map to %OCSF.User{} and carries privileges" do
      opts =
        base_opts()
        |> Keyword.put(:updated_user, %{uid: "u1", name: "Jane R."})
        |> Keyword.put(:privileges, ["billing:write"])

      assert {:ok, event} = UserManagement.assign_privileges(opts)
      assert %User{uid: "u1", name: "Jane R."} = event.updated_user
      assert event.privileges == ["billing:write"]
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      assert {:ok, event} = UserManagement.disable(Keyword.put(base_opts(), :status, :Failure))
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} = UserManagement.create(Keyword.delete(base_opts(), :severity))
      assert event.severity_id == 1
    end

    test "auto-generates metadata.uid and stamps version" do
      assert {:ok, event} = UserManagement.create(base_opts())
      assert event.metadata.version == "1.9.0"
      assert byte_size(event.metadata.uid) > 0
    end

    test "auto-stamps correlation_uid from scope" do
      OCSF.Correlation.with("corr-um-1", fn ->
        assert {:ok, event} = UserManagement.lock(base_opts())
        assert event.metadata.correlation_uid == "corr-um-1"
      end)
    end

    test "passes optional actor, service, and status_detail through" do
      opts =
        base_opts()
        |> Keyword.put(:actor, %Actor{user: %User{uid: "admin-1"}})
        |> Keyword.put(:service, %Service{name: "idp"})
        |> Keyword.put(:status_detail, "admin_initiated")

      assert {:ok, event} = UserManagement.password_reset(opts)
      assert event.actor.user.uid == "admin-1"
      assert event.service.name == "idp"
      assert event.status_detail == "admin_initiated"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} = UserManagement.unquote(fun)(user: %{uid: "u1"})
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks user as a required field" do
      assert "user" in SchemaValidator.required_fields(@schema)
    end

    test "activity_id values match OCSF.Activity for class 3007" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3007) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3007) |> Enum.map(fn {_n, id} -> 3007 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3007, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves user, updated_user, iam_roles, privileges" do
      {:ok, event} =
        UserManagement.assign_roles(
          user: %{uid: "u9", name: "Jane", email_addr: "jane@test.com"},
          updated_user: %{uid: "u9", name: "Jane R."},
          iam_roles: [%{name: "admin", uid: "role-1", privileges: ["*"]}],
          privileges: ["read", "write"],
          status: :Success
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.user == event.user
      assert reparsed.updated_user == event.updated_user
      assert reparsed.iam_roles == event.iam_roles
      assert reparsed.privileges == ["read", "write"]
      assert reparsed.class_uid == 3007
      assert reparsed.activity_id == 16
    end

    test "serialized map carries _name labels for class/activity" do
      {:ok, event} = UserManagement.create(base_opts())
      map = OCSF.to_map(event)
      assert map[:class_name] == "User Management"
      assert map[:activity_name] == "Create"
    end
  end

  describe "redaction" do
    test "deny policy nils PII fields on the user" do
      {:ok, event} =
        UserManagement.create(user: %{uid: "u1", name: "Jane", email_addr: "jane@test.com"})

      policy = %Policy{deny: [:identity, :contact]}
      redacted = OCSF.redact(event, policy)

      assert redacted.user.name == nil
      assert redacted.user.email_addr == nil
      assert redacted.user.uid == "u1"
    end

    test "deny policy nils PII fields on the updated_user" do
      {:ok, event} =
        UserManagement.update(
          user: %{uid: "u1"},
          updated_user: %{uid: "u1", name: "Jane R.", email_addr: "jane@test.com"}
        )

      redacted = OCSF.redact(event, %Policy{deny: [:identity, :contact]})
      assert redacted.updated_user.name == nil
      assert redacted.updated_user.email_addr == nil
      assert redacted.updated_user.uid == "u1"
    end

    test "programmatic_credentials on iam_roles are always dropped" do
      {:ok, event} =
        UserManagement.assign_roles(
          user: %{uid: "u1"},
          iam_roles: [%{name: "admin", uid: "role-1", programmatic_credentials: ["AKIA123"]}]
        )

      redacted = OCSF.redact(event, %Policy{})
      assert [%IamRole{programmatic_credentials: nil, uid: "role-1"}] = redacted.iam_roles
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = UserManagement.delete(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      assert {:ok, event} = UserManagement.create(Keyword.put(base_opts(), :severity, :Nope))
      assert event.severity_id == 0
    end

    test "accepts trace_uid, span_uid, explicit event_code, and unmapped" do
      opts =
        base_opts()
        |> Keyword.put(:trace_uid, "my-trace")
        |> Keyword.put(:span_uid, "my-span")
        |> Keyword.put(:event_code, "um:create")
        |> Keyword.put(:unmapped, %{"k" => "v"})

      assert {:ok, event} = UserManagement.create(opts)
      assert event.metadata.trace_uid == "my-trace"
      assert event.metadata.span_uid == "my-span"
      assert event.metadata.event_code == "um:create"
      assert event.unmapped == %{"k" => "v"}
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{um_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :um_fmt)
      assert {:ok, event} = UserManagement.create(opts)
      assert event.metadata.event_code == "user_management:create"
    end

    test "nonexistent format name leaves event_code nil" do
      opts = Keyword.put(base_opts(), :event_code_format, :nope)
      assert {:ok, event} = UserManagement.create(opts)
      assert event.metadata.event_code == nil
    end
  end
end
