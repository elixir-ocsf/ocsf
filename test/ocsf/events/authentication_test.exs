defmodule OCSF.Events.AuthenticationTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, Error, HttpRequest, Metadata, NetworkEndpoint, Product, Service, User}
  alias OCSF.Events.Authentication

  defp base_opts do
    [
      user: %User{uid: "u1"},
      severity: :Informational,
      status: :Success,
      metadata: %{product: %Product{name: "Test"}}
    ]
  end

  describe "logon/1" do
    test "builds valid event with correct UIDs" do
      assert {:ok, event} = Authentication.logon(base_opts())
      assert event.class_uid == 3002
      assert event.category_uid == 3
      assert event.type_uid == 300_201
      assert event.activity_id == 1
    end
  end

  describe "logoff/1" do
    test "sets activity_id 2" do
      assert {:ok, event} = Authentication.logoff(base_opts())
      assert event.activity_id == 2
      assert event.type_uid == 300_202
    end
  end

  describe "preauth/1" do
    test "sets activity_id 6" do
      assert {:ok, event} = Authentication.preauth(base_opts())
      assert event.activity_id == 6
      assert event.type_uid == 300_206
    end
  end

  describe "account_switch/1" do
    test "sets activity_id 7" do
      assert {:ok, event} = Authentication.account_switch(base_opts())
      assert event.activity_id == 7
      assert event.type_uid == 300_207
    end
  end

  describe "auto-generated metadata" do
    test "auto-generates metadata.uid as UUIDv7" do
      assert {:ok, event} = Authentication.logon(base_opts())
      assert byte_size(event.metadata.uid) > 0

      assert String.match?(
               event.metadata.uid,
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
             )
    end

    test "auto-sets metadata.version to 1.8.0" do
      assert {:ok, event} = Authentication.logon(base_opts())
      assert event.metadata.version == "1.8.0"
    end
  end

  describe "atom resolution" do
    test "resolves severity atom to severity_id" do
      assert {:ok, event} =
               Authentication.logon(Keyword.put(base_opts(), :severity, :High))

      assert event.severity_id == 4
    end

    test "resolves status atom to status_id" do
      assert {:ok, event} =
               Authentication.logon(Keyword.put(base_opts(), :status, :Failure))

      assert event.status_id == 2
    end

    test "resolves auth_protocol atom to auth_protocol_id" do
      opts = Keyword.put(base_opts(), :auth_protocol, :SAML)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.auth_protocol_id == 5
    end
  end

  describe "correlation" do
    test "auto-stamps correlation_uid from OCSF.Correlation scope" do
      OCSF.Correlation.with("corr-test-123", fn ->
        assert {:ok, event} = Authentication.logon(base_opts())
        assert event.metadata.correlation_uid == "corr-test-123"
      end)
    end
  end

  describe "authentication_ticket/1" do
    test "sets activity_id 3" do
      assert {:ok, event} = Authentication.authentication_ticket(base_opts())
      assert event.activity_id == 3
      assert event.type_uid == 300_203
    end
  end

  describe "error cases" do
    test "returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)
      assert {:error, %Error{}} = Authentication.logon(opts)
    end

    test "logoff returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)
      assert {:error, %Error{}} = Authentication.logoff(opts)
    end

    test "preauth returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)
      assert {:error, %Error{}} = Authentication.preauth(opts)
    end

    test "authentication_ticket returns {:error, _} when user is missing" do
      opts = Keyword.delete(base_opts(), :user)
      assert {:error, %Error{}} = Authentication.authentication_ticket(opts)
    end
  end

  describe "shortcut keys" do
    test "accepts correlation_uid at top level" do
      opts = Keyword.put(base_opts(), :correlation_uid, "my-corr")
      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.correlation_uid == "my-corr"
    end

    test "accepts trace_uid at top level" do
      opts = Keyword.put(base_opts(), :trace_uid, "my-trace")
      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.trace_uid == "my-trace"
    end

    test "accepts event_code at top level" do
      opts = Keyword.put(base_opts(), :event_code, "auth:logon")
      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.event_code == "auth:logon"
    end

    test "accepts span_uid at top level" do
      opts = Keyword.put(base_opts(), :span_uid, "my-span")
      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.span_uid == "my-span"
    end
  end

  describe "event_code_format integration" do
    test "applies event_code_format from opts when no explicit event_code" do
      Application.put_env(:ocsf, :event_code,
        formats: %{
          test_fmt: %{fields: [[:class_name], [:activity_name]], separator: ":"}
        }
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts = Keyword.put(base_opts(), :event_code_format, :test_fmt)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.event_code == "authentication:logon"
    end

    test "applies default_format from config when no explicit event_code or format" do
      Application.put_env(:ocsf, :event_code,
        default_format: :auto_fmt,
        formats: %{
          auto_fmt: %{fields: [[:class_name], [:activity_name]], separator: "-"}
        }
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      assert {:ok, event} = Authentication.logon(base_opts())
      assert event.metadata.event_code == "authentication-logon"
    end

    test "explicit event_code takes precedence over event_code_format" do
      Application.put_env(:ocsf, :event_code,
        formats: %{
          test_fmt: %{fields: [[:class_name]], separator: ":"}
        }
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      opts =
        base_opts()
        |> Keyword.put(:event_code, "explicit:code")
        |> Keyword.put(:event_code_format, :test_fmt)

      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.event_code == "explicit:code"
    end

    test "nonexistent format name leaves event_code nil" do
      opts = Keyword.put(base_opts(), :event_code_format, :nonexistent)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.metadata.event_code == nil
    end
  end

  describe "auth_protocol resolution" do
    test "resolves integer auth_protocol_id directly" do
      opts = Keyword.put(base_opts(), :auth_protocol, 5)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.auth_protocol_id == 5
    end

    test "nil auth_protocol leaves auth_protocol_id nil" do
      assert {:ok, event} = Authentication.logon(base_opts())
      assert event.auth_protocol_id == nil
    end
  end

  describe "severity and status defaults" do
    test "nil severity defaults to Informational (1)" do
      opts = Keyword.delete(base_opts(), :severity)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.severity_id == 1
    end

    test "nil status defaults to Unknown (0)" do
      opts = Keyword.delete(base_opts(), :status)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.severity_id == 1
    end

    test "integer severity is passed through" do
      opts = Keyword.put(base_opts(), :severity, 4)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.severity_id == 4
    end

    test "integer status is passed through" do
      opts = Keyword.put(base_opts(), :status, 2)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.status_id == 2
    end
  end

  describe "metadata from struct" do
    test "accepts OCSF.Metadata struct as metadata" do
      opts =
        Keyword.put(base_opts(), :metadata, %Metadata{
          uid: "pre-set-uid",
          version: "1.8.0",
          product: %Product{name: "Test"}
        })

      assert {:ok, event} = Authentication.logon(opts)
      # version is always overridden to library version
      assert event.metadata.version == "1.8.0"
    end
  end

  describe "optional fields passthrough" do
    test "passes actor, http_request, src_endpoint, dst_endpoint, service, raw_data, unmapped" do
      opts =
        base_opts()
        |> Keyword.put(:actor, %Actor{user: %User{uid: "a-u1"}})
        |> Keyword.put(:http_request, %HttpRequest{url: "https://test.com"})
        |> Keyword.put(:src_endpoint, %NetworkEndpoint{ip: {10, 0, 0, 1}})
        |> Keyword.put(:dst_endpoint, %NetworkEndpoint{hostname: "dst.example.com"})
        |> Keyword.put(:service, %Service{name: "svc"})
        |> Keyword.put(:raw_data, "raw")
        |> Keyword.put(:unmapped, %{"k" => "v"})
        |> Keyword.put(:status_detail, "detail")

      assert {:ok, event} = Authentication.logon(opts)
      assert event.actor.user.uid == "a-u1"
      assert event.http_request.url == "https://test.com"
      assert event.src_endpoint.ip == {10, 0, 0, 1}
      assert event.dst_endpoint.hostname == "dst.example.com"
      assert event.service.name == "svc"
      assert event.raw_data == "raw"
      assert event.unmapped == %{"k" => "v"}
      assert event.status_detail == "detail"
    end

    test "accepts explicit time" do
      t = ~U[2025-01-01 00:00:00Z]
      opts = Keyword.put(base_opts(), :time, t)
      assert {:ok, event} = Authentication.logon(opts)
      assert event.time == t
    end
  end

  describe "unmapped guard" do
    test "builder does not populate unmapped unless explicitly provided" do
      {:ok, event} = Authentication.logon(base_opts())
      assert event.unmapped == nil
    end

    test "builder passes through explicit unmapped" do
      {:ok, event} = Authentication.logon(base_opts() ++ [unmapped: %{custom: "data"}])
      assert event.unmapped == %{custom: "data"}
    end

    test "serialized output omits unmapped when nil" do
      {:ok, event} = Authentication.logon(base_opts())
      map = OCSF.to_map(event)
      refute Map.has_key?(map, :unmapped)
    end

    test "serialized output includes unmapped when set" do
      {:ok, event} = Authentication.logon(base_opts() ++ [unmapped: %{x: 1}])
      map = OCSF.to_map(event)
      assert map[:unmapped] == %{x: 1}
    end
  end
end
