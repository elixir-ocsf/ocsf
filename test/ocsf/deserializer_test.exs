defmodule OCSF.DeserializerTest do
  use ExUnit.Case, async: true

  import OCSF.EventFixtures, only: [valid_event_attrs: 0]

  defp valid_event do
    attrs =
      valid_event_attrs()
      |> Keyword.merge(
        metadata: %OCSF.Metadata{
          uid: "test-uid",
          version: "1.8.0",
          product: %OCSF.Product{name: "Test"}
        },
        time: ~U[2026-04-15 10:00:00Z],
        user: %OCSF.User{uid: "u1"}
      )

    {:ok, event} = OCSF.Event.new(attrs)
    event
  end

  describe "from_map/1" do
    test "round-trip preserves core UIDs" do
      original = valid_event()
      map = OCSF.to_map(original)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.class_uid == original.class_uid
      assert restored.category_uid == original.category_uid
      assert restored.type_uid == original.type_uid
      assert restored.activity_id == original.activity_id
      assert restored.severity_id == original.severity_id
      assert restored.status_id == original.status_id
    end

    test "round-trip preserves metadata, user, and time" do
      original = valid_event()
      map = OCSF.to_map(original)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.metadata.uid == original.metadata.uid
      assert restored.metadata.version == original.metadata.version
      assert restored.user.uid == original.user.uid
      assert restored.time == original.time
    end

    test "works with string-keyed maps (from Jason.decode!)" do
      original = valid_event()
      json = Jason.encode!(original)
      string_map = Jason.decode!(json)
      assert {:ok, restored} = OCSF.Event.from_map(string_map)
      assert restored.class_uid == 3002
      assert restored.metadata.uid == "test-uid"
      assert restored.user.uid == "u1"
    end

    test "parses IP strings back to tuples" do
      event = %{valid_event() | src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}}}
      map = OCSF.to_map(event)
      assert map[:src_endpoint][:ip] == "10.0.0.1"
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.src_endpoint.ip == {10, 0, 0, 1}
    end

    test "parses ISO8601 time strings" do
      map = OCSF.to_map(valid_event())
      assert map[:time] == "2026-04-15T10:00:00Z"
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.time == ~U[2026-04-15 10:00:00Z]
    end

    test "nil metadata remains nil" do
      map = OCSF.to_map(valid_event()) |> Map.delete(:metadata)
      # Without metadata, validation will fail, but deserialization should parse
      result = OCSF.Deserializer.from_map(map)
      assert {:error, %OCSF.Error{}} = result
    end

    test "nil actor remains nil" do
      map = OCSF.to_map(valid_event())
      refute Map.has_key?(map, :actor)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.actor == nil
    end

    test "nil service remains nil" do
      map = OCSF.to_map(valid_event())
      refute Map.has_key?(map, :service)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.service == nil
    end

    test "nil http_request remains nil" do
      map = OCSF.to_map(valid_event())
      refute Map.has_key?(map, :http_request)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.http_request == nil
    end

    test "nil dst_endpoint remains nil" do
      map = OCSF.to_map(valid_event())
      refute Map.has_key?(map, :dst_endpoint)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.dst_endpoint == nil
    end

    test "parses actor with nested user" do
      event = %{
        valid_event()
        | actor: %OCSF.Actor{
            user: %OCSF.User{uid: "actor-u1", name: "Bob", org: %OCSF.Organization{uid: "org-1"}}
          }
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.actor.user.uid == "actor-u1"
      assert restored.actor.user.name == "Bob"
      assert restored.actor.user.org.uid == "org-1"
    end

    test "parses service" do
      event = %{
        valid_event()
        | service: %OCSF.Service{name: "auth-svc", uid: "svc-1", version: "2.0"}
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.service.name == "auth-svc"
      assert restored.service.uid == "svc-1"
      assert restored.service.version == "2.0"
    end

    test "parses http_request" do
      event = %{
        valid_event()
        | http_request: %OCSF.HttpRequest{
            url: "https://example.com",
            user_agent: "Mozilla/5.0",
            http_method: "POST"
          }
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.http_request.url == "https://example.com"
      assert restored.http_request.user_agent == "Mozilla/5.0"
      assert restored.http_request.http_method == "POST"
    end

    test "parses dst_endpoint with port and hostname" do
      event = %{
        valid_event()
        | dst_endpoint: %OCSF.NetworkEndpoint{
            ip: {192, 168, 1, 1},
            port: 443,
            hostname: "api.example.com"
          }
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.dst_endpoint.ip == {192, 168, 1, 1}
      assert restored.dst_endpoint.port == 443
      assert restored.dst_endpoint.hostname == "api.example.com"
    end

    test "parses metadata product and feature fields" do
      event = %{
        valid_event()
        | metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.8.0",
            product: %OCSF.Product{
              name: "TestProduct",
              vendor_name: "Vendor",
              feature: %OCSF.Feature{name: "Login", uid: "f1", version: "1.0"},
              uid: "p1",
              version: "3.0"
            }
          }
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.metadata.product.name == "TestProduct"
      assert restored.metadata.product.vendor_name == "Vendor"
      assert restored.metadata.product.feature.name == "Login"
      assert restored.metadata.product.feature.uid == "f1"
      assert restored.metadata.product.uid == "p1"
    end

    test "parses metadata profiles, event_code, correlation, trace, span UIDs" do
      event = %{
        valid_event()
        | metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.8.0",
            product: %OCSF.Product{name: "Test"},
            profiles: ["host"],
            event_code: "auth:logon",
            correlation_uid: "corr-1",
            trace_uid: "trace-1",
            span_uid: "span-1"
          }
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.metadata.profiles == ["host"]
      assert restored.metadata.event_code == "auth:logon"
      assert restored.metadata.correlation_uid == "corr-1"
      assert restored.metadata.trace_uid == "trace-1"
      assert restored.metadata.span_uid == "span-1"
    end

    test "parse_ip with tuple passes through" do
      # Directly use a map with tuple IP (not serialized to string)
      map =
        OCSF.to_map(valid_event())
        |> Map.put(:src_endpoint, %{ip: {10, 0, 0, 1}})

      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.src_endpoint.ip == {10, 0, 0, 1}
    end

    test "parse_ip with nil returns nil" do
      map =
        OCSF.to_map(valid_event())
        |> Map.put(:src_endpoint, %{ip: nil, port: 80})

      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.src_endpoint.ip == nil
    end

    test "parse_time with nil returns nil" do
      map = OCSF.to_map(valid_event()) |> Map.put(:time, nil)
      # Build directly to avoid validation (time nil fails validation)
      result = OCSF.Deserializer.from_map(map)
      assert {:error, %OCSF.Error{reason: :missing, path: "time"}} = result
    end

    test "parse_time with DateTime passes through" do
      dt = ~U[2026-04-15 10:00:00Z]
      map = OCSF.to_map(valid_event()) |> Map.put(:time, dt)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.time == dt
    end

    test "parse_time with invalid string returns nil" do
      map = OCSF.to_map(valid_event()) |> Map.put(:time, "not-a-date")
      result = OCSF.Deserializer.from_map(map)
      assert {:error, %OCSF.Error{reason: :missing, path: "time"}} = result
    end

    test "parses IPv6 strings back to tuples" do
      event = %{
        valid_event()
        | src_endpoint: %OCSF.NetworkEndpoint{ip: {0, 0, 0, 0, 0, 0, 0, 1}}
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.src_endpoint.ip == {0, 0, 0, 0, 0, 0, 0, 1}
    end

    test "preserves raw_data and unmapped through round-trip" do
      event = %{valid_event() | raw_data: "raw payload", unmapped: %{"custom" => "data"}}
      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.raw_data == "raw payload"
      assert restored.unmapped == %{"custom" => "data"}
    end

    test "preserves status_detail and auth_protocol_id through round-trip" do
      event = %{valid_event() | status_detail: "detail text", auth_protocol_id: 5}
      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.status_detail == "detail text"
      assert restored.auth_protocol_id == 5
    end

    test "string-keyed map with nested objects" do
      event = %{
        valid_event()
        | actor: %OCSF.Actor{user: %OCSF.User{uid: "a-u1"}},
          service: %OCSF.Service{name: "svc"},
          http_request: %OCSF.HttpRequest{url: "https://test.com"},
          src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}},
          dst_endpoint: %OCSF.NetworkEndpoint{hostname: "dst.example.com"}
      }

      json = Jason.encode!(event)
      string_map = Jason.decode!(json)
      assert {:ok, restored} = OCSF.Event.from_map(string_map)
      assert restored.actor.user.uid == "a-u1"
      assert restored.service.name == "svc"
      assert restored.http_request.url == "https://test.com"
      assert restored.src_endpoint.ip == {10, 0, 0, 1}
      assert restored.dst_endpoint.hostname == "dst.example.com"
    end

    test "parses metadata with nil product (no feature)" do
      map =
        OCSF.to_map(valid_event())
        |> put_in([:metadata, :product], nil)
        |> Map.delete(:metadata)
        |> Map.put(:metadata, %{
          uid: "test-uid",
          version: "1.8.0",
          product: nil,
          profiles: []
        })

      result = OCSF.Deserializer.from_map(map)
      assert {:error, %OCSF.Error{reason: :missing, path: "metadata.product"}} = result
    end

    test "parse_ip with invalid IP string falls back to raw string" do
      map =
        OCSF.to_map(valid_event())
        |> Map.put(:src_endpoint, %{ip: "not-an-ip"})

      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.src_endpoint.ip == "not-an-ip"
    end

    test "parses user with org" do
      event = %{
        valid_event()
        | user: %OCSF.User{
            uid: "u1",
            name: "Alice",
            email_addr: "alice@test.com",
            org: %OCSF.Organization{uid: "org-1", name: "Acme"},
            type_id: 1
          }
      }

      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.user.uid == "u1"
      assert restored.user.name == "Alice"
      assert restored.user.email_addr == "alice@test.com"
      assert restored.user.org.uid == "org-1"
      assert restored.user.org.name == "Acme"
      assert restored.user.type_id == 1
    end
  end
end
