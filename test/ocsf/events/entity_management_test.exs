defmodule OCSF.Events.EntityManagementTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Entity, Error, Policy, Product, Service, User}
  alias OCSF.Events.EntityManagement
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("entity_management")

  defp base_opts do
    [
      entity: %Entity{uid: "e1", type: "User", name: "Jane"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    test "create/1 -> activity 1" do
      assert {:ok, event} = EntityManagement.create(base_opts())
      assert event.class_uid == 3004
      assert event.category_uid == 3
      assert event.activity_id == 1
      assert event.type_uid == 300_401
    end

    test "read/1 -> activity 2" do
      assert {:ok, event} = EntityManagement.read(base_opts())
      assert event.activity_id == 2
      assert event.type_uid == 300_402
    end

    test "update/1 -> activity 3" do
      assert {:ok, event} = EntityManagement.update(base_opts())
      assert event.activity_id == 3
      assert event.type_uid == 300_403
    end

    test "delete/1 -> activity 4" do
      assert {:ok, event} = EntityManagement.delete(base_opts())
      assert event.activity_id == 4
      assert event.type_uid == 300_404
    end

    test "activate/1 -> activity 10" do
      assert {:ok, event} = EntityManagement.activate(base_opts())
      assert event.activity_id == 10
      assert event.type_uid == 300_410
    end

    test "deactivate/1 -> activity 11" do
      assert {:ok, event} = EntityManagement.deactivate(base_opts())
      assert event.activity_id == 11
      assert event.type_uid == 300_411
    end
  end

  describe "entity requirement" do
    test "returns {:error, _} when entity is missing" do
      opts = Keyword.delete(base_opts(), :entity)
      assert {:error, %Error{reason: :missing, path: "entity"}} = EntityManagement.create(opts)
    end

    test "casts a plain map entity to %OCSF.Entity{}" do
      opts = Keyword.put(base_opts(), :entity, %{uid: "g1", type: "Group", name: "Admins"})
      assert {:ok, event} = EntityManagement.create(opts)
      assert %Entity{uid: "g1", type: "Group", name: "Admins"} = event.entity
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      assert {:ok, event} = EntityManagement.update(Keyword.put(base_opts(), :status, :Failure))
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} = EntityManagement.create(Keyword.delete(base_opts(), :severity))
      assert event.severity_id == 1
    end

    test "auto-generates metadata.uid and stamps version" do
      assert {:ok, event} = EntityManagement.create(base_opts())
      assert event.metadata.version == "1.8.0"
      assert byte_size(event.metadata.uid) > 0
    end

    test "auto-stamps correlation_uid from scope" do
      OCSF.Correlation.with("corr-em-1", fn ->
        assert {:ok, event} = EntityManagement.update(base_opts())
        assert event.metadata.correlation_uid == "corr-em-1"
      end)
    end

    test "passes optional actor and service through" do
      opts =
        base_opts()
        |> Keyword.put(:actor, %Actor{user: %User{uid: "admin-1"}})
        |> Keyword.put(:service, %Service{name: "scim"})
        |> Keyword.put(:status_detail, "synced")

      assert {:ok, event} = EntityManagement.create(opts)
      assert event.actor.user.uid == "admin-1"
      assert event.service.name == "scim"
      assert event.status_detail == "synced"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- [
          create: 1,
          read: 2,
          update: 3,
          delete: 4,
          activate: 10,
          deactivate: 11
        ] do
      test "#{fun} event passes schema validation" do
        {:ok, event} = EntityManagement.unquote(fun)(entity: %{uid: "e1", type: "User"})
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks entity as a required field" do
      assert "entity" in SchemaValidator.required_fields(@schema)
    end

    test "activity_id values match OCSF.Activity for class 3004" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3004) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3004) |> Enum.map(fn {_n, id} -> 3004 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3004, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves the entity" do
      {:ok, event} =
        EntityManagement.update(
          entity: %{uid: "e9", type: "User", name: "Jane", email: "jane@test.com"},
          status: :Success
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.entity == event.entity
      assert reparsed.class_uid == 3004
      assert reparsed.activity_id == 3
    end

    test "serialized map carries entity with _name labels for class/activity" do
      {:ok, event} = EntityManagement.create(base_opts())
      map = OCSF.to_map(event)
      assert map[:entity] == %{uid: "e1", type: "User", name: "Jane"}
      assert map[:class_name] == "Entity Management"
      assert map[:activity_name] == "Create"
    end
  end

  describe "redaction" do
    test "deny policy nils PII fields on the entity" do
      {:ok, event} =
        EntityManagement.create(
          entity: %{uid: "e1", type: "User", name: "Jane", email: "jane@test.com"}
        )

      policy = %Policy{deny: [:identity, :contact]}
      redacted = OCSF.redact(event, policy)

      assert redacted.entity.name == nil
      assert redacted.entity.email == nil
      # non-denied fields survive
      assert redacted.entity.uid == "e1"
      assert redacted.entity.type == "User"
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = EntityManagement.create(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      assert {:ok, event} = EntityManagement.create(Keyword.put(base_opts(), :severity, :Nope))
      assert event.severity_id == 0
    end

    test "accepts an %OCSF.Metadata{} struct as metadata" do
      opts =
        Keyword.put(base_opts(), :metadata, %OCSF.Metadata{
          uid: "pre-set",
          version: "0.0.0",
          product: %Product{name: "Test"},
          trace_uid: "t-1"
        })

      assert {:ok, event} = EntityManagement.create(opts)
      assert event.metadata.version == "1.8.0"
      assert event.metadata.trace_uid == "t-1"
    end

    test "accepts trace_uid, span_uid, and explicit event_code at top level" do
      opts =
        base_opts()
        |> Keyword.put(:trace_uid, "my-trace")
        |> Keyword.put(:span_uid, "my-span")
        |> Keyword.put(:event_code, "em:create")
        |> Keyword.put(:unmapped, %{"k" => "v"})

      assert {:ok, event} = EntityManagement.create(opts)
      assert event.metadata.trace_uid == "my-trace"
      assert event.metadata.span_uid == "my-span"
      assert event.metadata.event_code == "em:create"
      assert event.unmapped == %{"k" => "v"}
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{em_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :em_fmt)
      assert {:ok, event} = EntityManagement.create(opts)
      assert event.metadata.event_code == "entity_management:create"
    end

    test "applies default_format from config" do
      Application.put_env(:ocsf, :event_code,
        default_format: :auto_em,
        formats: %{auto_em: %{fields: [[:class_name], [:activity_name]], separator: "-"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      assert {:ok, event} = EntityManagement.update(base_opts())
      assert event.metadata.event_code == "entity_management-update"
    end

    test "nonexistent format name leaves event_code nil" do
      opts = Keyword.put(base_opts(), :event_code_format, :nope)
      assert {:ok, event} = EntityManagement.create(opts)
      assert event.metadata.event_code == nil
    end
  end
end
