defmodule OCSF.Events.ApiActivityTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Api, Error, NetworkEndpoint, Policy, Product, Service, User}
  alias OCSF.Events.ApiActivity
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("api_activity")

  @activities [create: 1, read: 2, update: 3, delete: 4]

  defp base_opts do
    [
      api: %Api{operation: "CreateUser"},
      actor: %Actor{user: %User{uid: "admin-1"}},
      src_endpoint: %NetworkEndpoint{ip: "10.0.0.1"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "activity builders set the right UIDs" do
    for {fun, activity} <- @activities do
      test "#{fun}/1 -> activity #{activity}" do
        assert {:ok, event} = ApiActivity.unquote(fun)(base_opts())
        assert event.class_uid == 6003
        assert event.category_uid == 6
        assert event.activity_id == unquote(activity)
        assert event.type_uid == 6003 * 100 + unquote(activity)
      end
    end
  end

  describe "required fields" do
    test "returns {:error, _} when api is missing" do
      opts = Keyword.delete(base_opts(), :api)
      assert {:error, %Error{reason: :missing, path: "api"}} = ApiActivity.create(opts)
    end

    test "returns {:error, _} when actor is missing" do
      opts = Keyword.delete(base_opts(), :actor)
      assert {:error, %Error{reason: :missing, path: "actor"}} = ApiActivity.create(opts)
    end

    test "returns {:error, _} when src_endpoint is missing" do
      opts = Keyword.delete(base_opts(), :src_endpoint)
      assert {:error, %Error{reason: :missing, path: "src_endpoint"}} = ApiActivity.create(opts)
    end

    test "casts a plain map api (with nested service) to %OCSF.Api{}" do
      opts = Keyword.put(base_opts(), :api, %{operation: "ListUsers", service: %{name: "scim"}})
      assert {:ok, event} = ApiActivity.read(opts)
      assert %Api{operation: "ListUsers", service: %Service{name: "scim"}} = event.api
    end
  end

  describe "atom and field resolution" do
    test "resolves status atom to status_id" do
      assert {:ok, event} = ApiActivity.update(Keyword.put(base_opts(), :status, :Failure))
      assert event.status_id == 2
    end

    test "defaults severity to Informational (1)" do
      assert {:ok, event} = ApiActivity.create(Keyword.delete(base_opts(), :severity))
      assert event.severity_id == 1
    end

    test "passes optional http_request and status_detail through" do
      opts =
        base_opts()
        |> Keyword.put(:http_request, %{url: "/v1/users", http_method: "POST"})
        |> Keyword.put(:status_detail, "created")

      assert {:ok, event} = ApiActivity.create(opts)
      assert event.http_request.http_method == "POST"
      assert event.status_detail == "created"
    end
  end

  describe "OCSF schema conformance" do
    for {fun, activity} <- @activities do
      test "#{fun} event passes schema validation" do
        {:ok, event} =
          ApiActivity.unquote(fun)(
            api: %{operation: "Op"},
            actor: %{user: %{uid: "a1"}},
            src_endpoint: %{ip: "10.0.0.2"}
          )

        event_map = OCSF.to_map(event)
        assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
        assert event.activity_id == unquote(activity)
      end
    end

    test "schema marks api, actor, and src_endpoint as required fields" do
      required = SchemaValidator.required_fields(@schema)
      assert "api" in required
      assert "actor" in required
      assert "src_endpoint" in required
    end

    test "activity_id values match OCSF.Activity for class 6003" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")
      ours = OCSF.Activity.values(6003) |> Enum.map(fn {_n, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, ours)
    end

    test "type_uid values match class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(6003) |> Enum.map(fn {_n, id} -> 6003 * 100 + id end) |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "activity captions match our atom labels" do
      for {id_str, def} <- @schema["attributes"]["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        label = OCSF.Activity.label(6003, id)
        assert label != nil, "missing activity_id #{id} in OCSF.Activity"
        assert Atom.to_string(label) == def["caption"]
      end
    end
  end

  describe "serialization round-trip" do
    test "to_map/from_map preserves the api object" do
      {:ok, event} =
        ApiActivity.update(
          api: %{operation: "UpdateUser", version: "v1", service: %{name: "scim", uid: "svc-1"}},
          actor: %{user: %{uid: "a1"}},
          src_endpoint: %{ip: "10.0.0.3"}
        )

      assert {:ok, reparsed} = event |> OCSF.to_map() |> OCSF.from_map()
      assert reparsed.api == event.api
      assert reparsed.api.operation == "UpdateUser"
      assert reparsed.api.service.name == "scim"
      assert reparsed.class_uid == 6003
      assert reparsed.activity_id == 3
    end

    test "serialized map carries _name labels and the api operation" do
      {:ok, event} = ApiActivity.create(base_opts())
      map = OCSF.to_map(event)
      assert map[:category_name] == "Application Activity"
      assert map[:class_name] == "API Activity"
      assert map[:activity_name] == "Create"
      assert map[:api] == %{operation: "CreateUser"}
    end
  end

  describe "redaction" do
    test "deny policy nils PII on the actor user but keeps the api operation" do
      {:ok, event} =
        ApiActivity.create(
          api: %{operation: "CreateUser"},
          actor: %{user: %{uid: "a1", email_addr: "admin@test.com"}},
          src_endpoint: %{ip: "10.0.0.4"}
        )

      redacted = OCSF.redact(event, %Policy{deny: [:contact]})
      assert redacted.actor.user.email_addr == nil
      assert redacted.actor.user.uid == "a1"
      assert redacted.api.operation == "CreateUser"
    end
  end

  describe "passthrough and resolution branches" do
    test "integer severity and status are passed through" do
      opts = base_opts() |> Keyword.put(:severity, 4) |> Keyword.put(:status, 2)
      assert {:ok, event} = ApiActivity.delete(opts)
      assert event.severity_id == 4
      assert event.status_id == 2
    end

    test "unknown severity atom resolves to 0" do
      assert {:ok, event} = ApiActivity.create(Keyword.put(base_opts(), :severity, :Nope))
      assert event.severity_id == 0
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{api_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}}
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :api_fmt)
      assert {:ok, event} = ApiActivity.create(opts)
      assert event.metadata.event_code == "api_activity:create"
    end

    test "nonexistent format name leaves event_code nil" do
      opts = Keyword.put(base_opts(), :event_code_format, :nope)
      assert {:ok, event} = ApiActivity.create(opts)
      assert event.metadata.event_code == nil
    end
  end
end
