defmodule OCSF.SerializerTest do
  use ExUnit.Case, async: true

  import OCSF.EventFixtures, only: [valid_event_attrs: 0]

  defp valid_event do
    attrs =
      valid_event_attrs()
      |> Keyword.merge(
        metadata: %OCSF.Metadata{
          uid: "test-uid",
          version: "1.9.0",
          product: %OCSF.Product{name: "Test"}
        },
        time: ~U[2026-04-15 10:00:00Z],
        user: %OCSF.User{uid: "u1", org: %OCSF.Organization{uid: "org-1"}}
      )

    {:ok, event} = OCSF.Event.new(attrs)
    event
  end

  describe "to_map/1" do
    test "produces correct nested structure" do
      map = OCSF.to_map(valid_event())
      assert map[:category_uid] == 3
      assert map[:class_uid] == 3002
      assert map[:type_uid] == 300_201
      assert map[:activity_id] == 1
      assert map[:metadata][:uid] == "test-uid"
      assert map[:metadata][:version] == "1.9.0"
      assert map[:metadata][:product][:name] == "Test"
      assert map[:user][:uid] == "u1"
      assert map[:user][:org][:uid] == "org-1"
    end

    test "adds _name labels" do
      map = OCSF.to_map(valid_event())
      assert map[:category_name] == "Identity & Access Management"
      assert map[:class_name] == "Authentication"
      assert map[:activity_name] == "Logon"
      assert map[:severity] == "Informational"
      assert map[:status] == "Success"
    end

    test "omits nil fields" do
      map = OCSF.to_map(valid_event())
      refute Map.has_key?(map, :http_request)
      refute Map.has_key?(map, :src_endpoint)
      refute Map.has_key?(map, :dst_endpoint)
      refute Map.has_key?(map, :service)
      refute Map.has_key?(map, :raw_data)
      refute Map.has_key?(map, :unmapped)
      refute Map.has_key?(map, :status_detail)
      refute Map.has_key?(map, :auth_protocol_id)
    end

    test "serializes IP tuples to strings" do
      event = %{valid_event() | src_endpoint: %OCSF.NetworkEndpoint{ip: {192, 168, 1, 1}}}
      map = OCSF.to_map(event)
      assert map[:src_endpoint][:ip] == "192.168.1.1"
    end

    test "serializes DateTime to ISO8601" do
      map = OCSF.to_map(valid_event())
      assert map[:time] == "2026-04-15T10:00:00Z"
    end

    test "Jason.encode!/1 works on events via Jason.Encoder" do
      json = Jason.encode!(valid_event())
      assert byte_size(json) > 0
      decoded = Jason.decode!(json)
      assert decoded["class_uid"] == 3002
      assert decoded["metadata"]["uid"] == "test-uid"
    end

    test "to_json/1 works" do
      iodata = OCSF.to_json(valid_event())
      json = IO.iodata_to_binary(iodata)
      decoded = Jason.decode!(json)
      assert decoded["class_uid"] == 3002
    end

    test "serializes actor with nested user" do
      event = %{
        valid_event()
        | actor: %OCSF.Actor{
            user: %OCSF.User{uid: "actor-u1", name: "Bob"},
            session: "sess-123"
          }
      }

      map = OCSF.to_map(event)
      assert map[:actor][:user][:uid] == "actor-u1"
      assert map[:actor][:user][:name] == "Bob"
      assert map[:actor][:session] == "sess-123"
    end

    test "serializes service" do
      event = %{
        valid_event()
        | service: %OCSF.Service{name: "auth-svc", uid: "svc-1", version: "2.0"}
      }

      map = OCSF.to_map(event)
      assert map[:service][:name] == "auth-svc"
      assert map[:service][:uid] == "svc-1"
      assert map[:service][:version] == "2.0"
    end

    test "serializes product with feature" do
      event = %{
        valid_event()
        | metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
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
      assert map[:metadata][:product][:name] == "TestProduct"
      assert map[:metadata][:product][:vendor_name] == "Vendor"
      assert map[:metadata][:product][:feature][:name] == "Login"
      assert map[:metadata][:product][:feature][:uid] == "f1"
      assert map[:metadata][:product][:feature][:version] == "1.0"
      assert map[:metadata][:product][:uid] == "p1"
      assert map[:metadata][:product][:version] == "3.0"
    end

    test "serializes endpoint with port and hostname" do
      event = %{
        valid_event()
        | dst_endpoint: %OCSF.NetworkEndpoint{
            ip: {192, 168, 1, 1},
            port: 8080,
            hostname: "api.example.com"
          }
      }

      map = OCSF.to_map(event)
      assert map[:dst_endpoint][:ip] == "192.168.1.1"
      assert map[:dst_endpoint][:port] == 8080
      assert map[:dst_endpoint][:hostname] == "api.example.com"
    end

    test "serializes http_request" do
      event = %{
        valid_event()
        | http_request: %OCSF.HttpRequest{
            url: "https://example.com",
            user_agent: "Mozilla/5.0",
            http_method: "POST"
          }
      }

      map = OCSF.to_map(event)
      assert map[:http_request][:url] == "https://example.com"
      assert map[:http_request][:user_agent] == "Mozilla/5.0"
      assert map[:http_request][:http_method] == "POST"
    end

    test "omits empty profiles list" do
      map = OCSF.to_map(valid_event())
      refute Map.has_key?(map[:metadata], :profiles)
    end

    test "includes non-empty profiles list" do
      event = %{
        valid_event()
        | metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: %OCSF.Product{name: "Test"},
            profiles: ["host", "cloud"]
          }
      }

      map = OCSF.to_map(event)
      assert map[:metadata][:profiles] == ["host", "cloud"]
    end

    test "serializes IP string as-is" do
      event = %{
        valid_event()
        | src_endpoint: %OCSF.NetworkEndpoint{ip: "10.0.0.1"}
      }

      map = OCSF.to_map(event)
      assert map[:src_endpoint][:ip] == "10.0.0.1"
    end

    test "serializes auth_protocol_id with name" do
      event = %{valid_event() | auth_protocol_id: 5}
      map = OCSF.to_map(event)
      assert map[:auth_protocol_id] == 5
      assert map[:auth_protocol] == "SAML"
    end

    test "serializes auth_protocol_id with unknown id (no name)" do
      event = %{valid_event() | auth_protocol_id: 999}
      map = OCSF.to_map(event)
      assert map[:auth_protocol_id] == 999
      refute Map.has_key?(map, :auth_protocol)
    end

    test "serializes status_detail when present" do
      event = %{valid_event() | status_detail: "some detail"}
      map = OCSF.to_map(event)
      assert map[:status_detail] == "some detail"
    end

    test "serializes raw_data and unmapped" do
      event = %{valid_event() | raw_data: "raw payload", unmapped: %{"custom" => "data"}}
      map = OCSF.to_map(event)
      assert map[:raw_data] == "raw payload"
      assert map[:unmapped] == %{"custom" => "data"}
    end

    test "serializes metadata correlation, trace, span UIDs" do
      event = %{
        valid_event()
        | metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: %OCSF.Product{name: "Test"},
            correlation_uid: "corr-1",
            trace_uid: "trace-1",
            span_uid: "span-1",
            event_code: "auth:logon"
          }
      }

      map = OCSF.to_map(event)
      assert map[:metadata][:correlation_uid] == "corr-1"
      assert map[:metadata][:trace_uid] == "trace-1"
      assert map[:metadata][:span_uid] == "span-1"
      assert map[:metadata][:event_code] == "auth:logon"
    end

    test "nil metadata serializes to nil (omitted)" do
      {:ok, event} =
        OCSF.Event.new(
          metadata: nil,
          time: ~U[2026-04-15 10:00:00Z],
          category_uid: 3,
          class_uid: 3002,
          type_uid: 300_201,
          activity_id: 1,
          severity_id: 1,
          status_id: 1,
          user: %OCSF.User{uid: "u1"}
        )

      map = OCSF.Serializer.to_map(event)
      refute Map.has_key?(map, :metadata)
    end

    test "put_name handles nil name (unknown UIDs)" do
      # Build event with invalid category/class/activity UIDs to trigger put_name(map, _, nil)
      {:ok, event} =
        OCSF.Event.new(
          metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: %OCSF.Product{name: "Test"}
          },
          time: ~U[2026-04-15 10:00:00Z],
          category_uid: 99_999,
          class_uid: 99_999,
          type_uid: 99_999 * 100 + 98,
          activity_id: 98,
          severity_id: 98,
          status_id: 98,
          user: %OCSF.User{uid: "u1"}
        )

      map = OCSF.Serializer.to_map(event)
      # nil names should not appear as keys
      refute Map.has_key?(map, :category_name)
      refute Map.has_key?(map, :class_name)
      refute Map.has_key?(map, :activity_name)
      refute Map.has_key?(map, :severity)
      refute Map.has_key?(map, :status)
    end

    test "serializes metadata with nil product" do
      {:ok, event} =
        OCSF.Event.new(
          metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: nil
          },
          time: ~U[2026-04-15 10:00:00Z],
          category_uid: 3,
          class_uid: 3002,
          type_uid: 300_201,
          activity_id: 1,
          severity_id: 1,
          status_id: 1,
          user: %OCSF.User{uid: "u1"}
        )

      map = OCSF.Serializer.to_map(event)
      refute Map.has_key?(map[:metadata], :product)
    end

    test "serializes nil user (omitted)" do
      {:ok, event} =
        OCSF.Event.new(
          metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: %OCSF.Product{name: "Test"}
          },
          time: ~U[2026-04-15 10:00:00Z],
          category_uid: 3,
          class_uid: 3002,
          type_uid: 300_201,
          activity_id: 1,
          severity_id: 1,
          status_id: 1,
          user: nil
        )

      map = OCSF.Serializer.to_map(event)
      refute Map.has_key?(map, :user)
    end

    test "serializes feature nil inside product (omitted)" do
      {:ok, event} =
        OCSF.Event.new(
          metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: %OCSF.Product{name: "Test", feature: nil}
          },
          time: ~U[2026-04-15 10:00:00Z],
          category_uid: 3,
          class_uid: 3002,
          type_uid: 300_201,
          activity_id: 1,
          severity_id: 1,
          status_id: 1,
          user: %OCSF.User{uid: "u1"}
        )

      map = OCSF.Serializer.to_map(event)
      refute Map.has_key?(map[:metadata][:product], :feature)
    end

    test "nil time serializes to nil (omitted)" do
      {:ok, event} =
        OCSF.Event.new(
          metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.9.0",
            product: %OCSF.Product{name: "Test"}
          },
          time: nil,
          category_uid: 3,
          class_uid: 3002,
          type_uid: 300_201,
          activity_id: 1,
          severity_id: 1,
          status_id: 1,
          user: %OCSF.User{uid: "u1"}
        )

      map = OCSF.Serializer.to_map(event)
      refute Map.has_key?(map, :time)
    end
  end
end
