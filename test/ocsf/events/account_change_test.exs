defmodule OCSF.Events.AccountChangeTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, Policy, Product, Service, User}
  alias OCSF.Events.AccountChange
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("account_change")

  @activities [
    create: 1,
    enable: 2,
    password_change: 3,
    password_reset: 4,
    disable: 5,
    delete: 6,
    attach_policy: 7,
    detach_policy: 8,
    lock: 9,
    mfa_factor_enable: 10,
    mfa_factor_disable: 11,
    unlock: 12
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
        assert {:ok, event} = AccountChange.unquote(fun)(base_opts())
        assert event.class_uid == 3001
        assert event.category_uid == 3
        assert event.activity_id == unquote(activity)
        assert event.type_uid == 3001 * 100 + unquote(activity)
      end
    end
  end

  describe "user requirement" do
    test "returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)
      assert {:error, %Error{reason: :missing, path: "user"}} = AccountChange.create(opts)
    end

    test "casts a plain map user to %OCSF.User{}" do
      opts = Keyword.put(base_opts(), :user, %{uid: "u9", name: "Ada"})
      assert {:ok, event} = AccountChange.enable(opts)
      assert %User{uid: "u9", name: "Ada"} = event.user
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      assert {:ok, event} = AccountChange.disable(Keyword.put(base_opts(), :status, :Failure))
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} = AccountChange.create(Keyword.delete(base_opts(), :severity))
      assert event.severity_id == 1
    end

    test "auto-generates metadata.uid and stamps version" do
      assert {:ok, event} = AccountChange.create(base_opts())
      assert event.metadata.version == "1.8.0"
      assert byte_size(event.metadata.uid) > 0
    end

    test "auto-stamps correlation_uid from scope" do
      OCSF.Correlation.with("corr-ac-1", fn ->
        assert {:ok, event} = AccountChange.lock(base_opts())
        assert event.metadata.correlation_uid == "corr-ac-1"
      end)
    end

    test "passes optional actor, service, and status_detail through" do
      opts =
        base_opts()
        |> Keyword.put(:actor, %Actor{user: %User{uid: "admin-1"}})
        |> Keyword.put(:service, %Service{name: "idp"})
        |> Keyword.put(:status_detail, "user_self_service")

      assert {:ok, event} = AccountChange.password_reset(opts)
      assert event.actor.user.uid == "admin-1"
      assert event.service.name == "idp"
      assert event.status_detail == "user_self_service"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} = AccountChange.unquote(fun)(user: %{uid: "u1"})
        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks user as a required field" do
      assert "user" in SchemaValidator.required_fields(@schema)
    end

    test "activity_id values match OCSF.Activity for class 3001" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(3001) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3001) |> Enum.map(fn {_n, id} -> 3001 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(3001, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves the user" do
      {:ok, event} =
        AccountChange.password_change(
          user: %{uid: "u9", name: "Jane", email_addr: "jane@test.com"},
          status: :Success
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.user == event.user
      assert reparsed.class_uid == 3001
      assert reparsed.activity_id == 3
    end

    test "serialized map carries _name labels for class/activity" do
      {:ok, event} = AccountChange.create(base_opts())
      map = OCSF.to_map(event)
      assert map[:class_name] == "Account Change"
      assert map[:activity_name] == "Create"
    end
  end

  describe "redaction" do
    test "deny policy nils PII fields on the user" do
      {:ok, event} =
        AccountChange.create(user: %{uid: "u1", name: "Jane", email_addr: "jane@test.com"})

      policy = %Policy{deny: [:identity, :contact]}
      redacted = OCSF.redact(event, policy)

      assert redacted.user.name == nil
      assert redacted.user.email_addr == nil
      assert redacted.user.uid == "u1"
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = AccountChange.delete(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      assert {:ok, event} = AccountChange.create(Keyword.put(base_opts(), :severity, :Nope))
      assert event.severity_id == 0
    end

    test "accepts trace_uid, span_uid, explicit event_code, and unmapped" do
      opts =
        base_opts()
        |> Keyword.put(:trace_uid, "my-trace")
        |> Keyword.put(:span_uid, "my-span")
        |> Keyword.put(:event_code, "ac:create")
        |> Keyword.put(:unmapped, %{"k" => "v"})

      assert {:ok, event} = AccountChange.create(opts)
      assert event.metadata.trace_uid == "my-trace"
      assert event.metadata.span_uid == "my-span"
      assert event.metadata.event_code == "ac:create"
      assert event.unmapped == %{"k" => "v"}
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{ac_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :ac_fmt)
      assert {:ok, event} = AccountChange.create(opts)
      assert event.metadata.event_code == "account_change:create"
    end

    test "nonexistent format name leaves event_code nil" do
      opts = Keyword.put(base_opts(), :event_code_format, :nope)
      assert {:ok, event} = AccountChange.create(opts)
      assert event.metadata.event_code == nil
    end
  end
end
