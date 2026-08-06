defmodule OCSF.Events.RoleManagementTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, IamRole, Policy, Product, Service, User}
  alias OCSF.Events.RoleManagement
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("role_management")

  @activities [
    create: 1,
    update: 2,
    delete: 3,
    assign_privileges: 4,
    remove_privileges: 5,
    assign_resources: 6,
    remove_resources: 7,
    attach_policies: 8,
    detach_policies: 9,
    add_programmatic_credentials: 10,
    remove_programmatic_credentials: 11
  ]

  defp base_opts do
    [
      iam_role: %IamRole{name: "admin", uid: "role-1"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    for {fun, activity} <- @activities do
      test "#{fun}/1 -> activity #{activity}" do
        assert {:ok, event} = RoleManagement.unquote(fun)(base_opts())
        assert event.class_uid == 3008
        assert event.category_uid == 3
        assert event.activity_id == unquote(activity)
        assert event.type_uid == 3008 * 100 + unquote(activity)
      end
    end

    test "exposes one builder per OCSF.Activity entry for class 3008" do
      ids = Enum.map(@activities, fn {_fun, id} -> id end)
      assert length(ids) == 11

      schema_ids =
        OCSF.Activity.values(3008)
        |> Enum.map(fn {_n, id} -> id end)
        |> Enum.reject(&(&1 in [0, 99]))

      assert Enum.sort(ids) == Enum.sort(schema_ids)
    end
  end

  describe "iam_role requirement" do
    test "returns {:error, _} when iam_role is missing" do
      opts = Keyword.delete(base_opts(), :iam_role)

      assert {:error, %Error{reason: :missing, path: "iam_role"}} =
               RoleManagement.create(opts)
    end

    test "casts a plain map iam_role to %OCSF.IamRole{}" do
      opts = Keyword.put(base_opts(), :iam_role, %{name: "auditor", uid: "role-9"})
      assert {:ok, event} = RoleManagement.update(opts)
      assert %IamRole{name: "auditor", uid: "role-9"} = event.iam_role
    end
  end

  describe "updated_role, privilege, and resource attributes" do
    test "casts updated_role map and carries privileges and resources" do
      opts =
        base_opts()
        |> Keyword.put(:updated_role, %{name: "admin", uid: "role-1", privileges: ["*"]})
        |> Keyword.put(:privileges, ["s3:read"])
        |> Keyword.put(:resources, ["arn:aws:s3:::bucket"])

      assert {:ok, event} = RoleManagement.assign_privileges(opts)
      assert %IamRole{name: "admin", privileges: ["*"]} = event.updated_role
      assert event.privileges == ["s3:read"]
      assert event.resources == ["arn:aws:s3:::bucket"]
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      assert {:ok, event} = RoleManagement.delete(Keyword.put(base_opts(), :status, :Failure))
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} = RoleManagement.create(Keyword.delete(base_opts(), :severity))
      assert event.severity_id == 1
    end

    test "passes optional actor, service, and status_detail through" do
      opts =
        base_opts()
        |> Keyword.put(:actor, %Actor{user: %User{uid: "admin-1"}})
        |> Keyword.put(:service, %Service{name: "idp"})
        |> Keyword.put(:status_detail, "iac_apply")

      assert {:ok, event} = RoleManagement.attach_policies(opts)
      assert event.actor.user.uid == "admin-1"
      assert event.service.name == "idp"
      assert event.status_detail == "iac_apply"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} = RoleManagement.unquote(fun)(iam_role: %{name: "admin", uid: "role-1"})
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks iam_role as a required field" do
      assert "iam_role" in SchemaValidator.required_fields(@schema)
    end

    test "activity_id values match OCSF.Activity for class 3008" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3008) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3008) |> Enum.map(fn {_n, id} -> 3008 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3008, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves iam_role, updated_role, privileges, resources" do
      {:ok, event} =
        RoleManagement.assign_resources(
          iam_role: %{
            name: "admin",
            uid: "role-1",
            account: "acme",
            policies: ["p1"],
            resources: ["arn:1"]
          },
          updated_role: %{name: "admin", uid: "role-1", resources: ["arn:1", "arn:2"]},
          privileges: ["s3:read"],
          resources: ["arn:2"],
          status: :Success
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.iam_role == event.iam_role
      assert reparsed.updated_role == event.updated_role
      assert reparsed.privileges == ["s3:read"]
      assert reparsed.resources == ["arn:2"]
      assert reparsed.class_uid == 3008
      assert reparsed.activity_id == 6
    end

    test "serialized map carries _name labels for class/activity" do
      {:ok, event} = RoleManagement.create(base_opts())
      map = OCSF.to_map(event)
      assert map[:class_name] == "Role Management"
      assert map[:activity_name] == "Create"
      assert map[:iam_role][:name] == "admin"
    end
  end

  describe "redaction" do
    test "programmatic_credentials on iam_role and updated_role are always dropped" do
      {:ok, event} =
        RoleManagement.add_programmatic_credentials(
          iam_role: %{name: "admin", uid: "role-1", programmatic_credentials: ["AKIA123"]},
          updated_role: %{name: "admin", uid: "role-1", programmatic_credentials: ["AKIA456"]}
        )

      redacted = OCSF.redact(event, %Policy{})
      assert redacted.iam_role.programmatic_credentials == nil
      assert redacted.updated_role.programmatic_credentials == nil
      assert redacted.iam_role.uid == "role-1"
    end

    test "deny policy nils PII fields on the actor user but keeps the role" do
      opts = Keyword.put(base_opts(), :actor, %{user: %{uid: "a1", email_addr: "admin@test.com"}})
      {:ok, event} = RoleManagement.create(opts)

      redacted = OCSF.redact(event, %Policy{deny: [:contact]})
      assert redacted.actor.user.email_addr == nil
      assert redacted.iam_role.name == "admin"
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = RoleManagement.delete(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      assert {:ok, event} = RoleManagement.create(Keyword.put(base_opts(), :severity, :Nope))
      assert event.severity_id == 0
    end

    test "accepts trace_uid, span_uid, explicit event_code, and unmapped" do
      opts =
        base_opts()
        |> Keyword.put(:trace_uid, "my-trace")
        |> Keyword.put(:span_uid, "my-span")
        |> Keyword.put(:event_code, "rm:create")
        |> Keyword.put(:unmapped, %{"k" => "v"})

      assert {:ok, event} = RoleManagement.create(opts)
      assert event.metadata.trace_uid == "my-trace"
      assert event.metadata.span_uid == "my-span"
      assert event.metadata.event_code == "rm:create"
      assert event.unmapped == %{"k" => "v"}
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{rm_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :rm_fmt)
      assert {:ok, event} = RoleManagement.create(opts)
      assert event.metadata.event_code == "role_management:create"
    end
  end
end
