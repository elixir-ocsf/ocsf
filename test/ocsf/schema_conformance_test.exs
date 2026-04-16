defmodule OCSF.SchemaConformanceTest do
  use ExUnit.Case, async: true

  alias OCSF.Events.Authentication
  alias OCSF.Test.SchemaValidator

  @schema SchemaValidator.load_class_schema("authentication")

  describe "Authentication builder output vs OCSF schema" do
    test "logon event passes schema validation" do
      {:ok, event} = Authentication.logon(user: %{uid: "u1"}, service: %{name: "svc"})
      event_map = OCSF.to_map(event)
      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
    end

    test "logoff event passes schema validation" do
      {:ok, event} = Authentication.logoff(user: %{uid: "u1"}, service: %{name: "svc"})
      event_map = OCSF.to_map(event)
      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
    end

    test "preauth event passes schema validation" do
      {:ok, event} = Authentication.preauth(user: %{uid: "u1"}, service: %{name: "svc"})
      event_map = OCSF.to_map(event)
      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
    end

    test "authentication_ticket event passes schema validation" do
      {:ok, event} =
        Authentication.authentication_ticket(user: %{uid: "u1"}, service: %{name: "svc"})

      event_map = OCSF.to_map(event)
      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
    end

    test "account_switch event passes schema validation" do
      {:ok, event} =
        Authentication.account_switch(user: %{uid: "u1"}, service: %{name: "svc"})

      event_map = OCSF.to_map(event)
      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
    end

    test "fully populated logon event passes schema validation" do
      {:ok, event} =
        Authentication.logon(
          user: %{uid: "u1", name: "Jane", email_addr: "jane@test.com", org: %{uid: "acme"}},
          http_request: %{url: "/login", http_method: "POST", user_agent: "Mozilla"},
          src_endpoint: %{ip: {10, 0, 0, 1}, port: 443},
          dst_endpoint: %{hostname: "auth.example.com"},
          service: %{name: "Cryptr Auth"},
          status: :Success,
          severity: :Informational,
          auth_protocol: :"OAUTH 2.0",
          status_detail: "logoff_user_initiated"
        )

      event_map = OCSF.to_map(event)
      assert {:ok, []} = SchemaValidator.validate_event(event_map, @schema)
    end
  end

  describe "required fields" do
    test "schema requires the expected fields" do
      required = SchemaValidator.required_fields(@schema)
      assert "activity_id" in required
      assert "category_uid" in required
      assert "class_uid" in required
      assert "metadata" in required
      assert "severity_id" in required
      assert "time" in required
      assert "type_uid" in required
      assert "user" in required
    end
  end

  describe "enum values match our modules" do
    test "activity_id values match OCSF.Activity for class 3002" do
      schema_values = SchemaValidator.enum_values(@schema, "activity_id")

      our_values =
        OCSF.Activity.values(3002) |> Enum.map(fn {_name, id} -> id end) |> MapSet.new()

      assert MapSet.equal?(schema_values, our_values)
    end

    test "severity_id values match OCSF.Severity" do
      schema_values = SchemaValidator.enum_values(@schema, "severity_id")
      our_values = OCSF.Severity.values() |> Enum.map(fn {_name, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, our_values)
    end

    test "status_id values match OCSF.Status" do
      schema_values = SchemaValidator.enum_values(@schema, "status_id")
      our_values = OCSF.Status.values() |> Enum.map(fn {_name, id} -> id end) |> MapSet.new()
      assert MapSet.equal?(schema_values, our_values)
    end

    test "auth_protocol_id values match OCSF.AuthProtocol" do
      schema_values = SchemaValidator.enum_values(@schema, "auth_protocol_id")

      our_values =
        OCSF.AuthProtocol.values() |> Enum.map(fn {_name, id} -> id end) |> MapSet.new()

      assert MapSet.equal?(schema_values, our_values)
    end

    test "type_uid values match computed class_uid * 100 + activity_id" do
      schema_type_uids = SchemaValidator.enum_values(@schema, "type_uid")

      expected =
        OCSF.Activity.values(3002)
        |> Enum.map(fn {_name, id} -> 3002 * 100 + id end)
        |> MapSet.new()

      assert MapSet.equal?(schema_type_uids, expected)
    end

    test "enum captions match our atom labels" do
      schema_attrs = @schema["attributes"]

      # Check activity_id captions
      for {id_str, def} <- schema_attrs["activity_id"]["enum"] do
        id = String.to_integer(id_str)
        our_label = OCSF.Activity.label(3002, id)
        assert our_label != nil, "missing activity_id #{id} in OCSF.Activity"

        assert Atom.to_string(our_label) == def["caption"],
               "activity_id #{id}: expected #{def["caption"]}, got #{our_label}"
      end

      # Check severity_id captions
      for {id_str, def} <- schema_attrs["severity_id"]["enum"] do
        id = String.to_integer(id_str)
        our_label = OCSF.Severity.name(id)
        assert our_label != nil, "missing severity_id #{id} in OCSF.Severity"

        assert Atom.to_string(our_label) == def["caption"],
               "severity_id #{id}: expected #{def["caption"]}, got #{our_label}"
      end

      # Check auth_protocol_id captions
      for {id_str, def} <- schema_attrs["auth_protocol_id"]["enum"] do
        id = String.to_integer(id_str)
        our_label = OCSF.AuthProtocol.name(id)
        assert our_label != nil, "missing auth_protocol_id #{id} in OCSF.AuthProtocol"

        assert Atom.to_string(our_label) == def["caption"],
               "auth_protocol_id #{id}: expected #{def["caption"]}, got #{our_label}"
      end
    end
  end

  describe "constraints" do
    test "at_least_one constraint requires service or dst_endpoint" do
      {:ok, event} = Authentication.logon(user: %{uid: "u1"})
      event_map = OCSF.to_map(event)

      # Without service or dst_endpoint, constraint is violated
      result = SchemaValidator.validate_event(event_map, @schema)

      case result do
        {:error, errors} ->
          assert Enum.any?(errors, &String.contains?(&1, "at least one"))

        {:ok, []} ->
          # If the builder auto-sets one, that's fine too
          assert Map.has_key?(event_map, :service) or Map.has_key?(event_map, :dst_endpoint)
      end
    end
  end
end
