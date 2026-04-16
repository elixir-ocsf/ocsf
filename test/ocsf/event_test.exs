defmodule OCSF.EventTest do
  use ExUnit.Case, async: true

  import OCSF.EventFixtures

  defp valid_attrs, do: valid_event_attrs()

  describe "new/1 from keyword list" do
    test "creates a valid event" do
      assert {:ok, %OCSF.Event{} = event} = OCSF.Event.new(valid_attrs())
      assert event.class_uid == 3002
      assert event.category_uid == 3
      assert event.activity_id == 1
      assert event.type_uid == 300_201
    end
  end

  describe "new/1 from map" do
    test "creates a valid event" do
      attrs = Map.new(valid_attrs())
      assert {:ok, %OCSF.Event{} = event} = OCSF.Event.new(attrs)
      assert event.class_uid == 3002
    end
  end

  describe "new/1 nested casting" do
    test "casts plain user map to User struct" do
      attrs = Keyword.put(valid_attrs(), :user, %{uid: "u1", name: "Alice"})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.User{uid: "u1", name: "Alice"} = event.user
    end

    test "casts plain http_request map to HttpRequest struct" do
      attrs = Keyword.put(valid_attrs(), :http_request, %{url: "https://example.com"})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.HttpRequest{url: "https://example.com"} = event.http_request
    end

    test "casts plain src_endpoint map to NetworkEndpoint struct" do
      attrs = Keyword.put(valid_attrs(), :src_endpoint, %{ip: {127, 0, 0, 1}, port: 443})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.NetworkEndpoint{ip: {127, 0, 0, 1}, port: 443} = event.src_endpoint
    end

    test "casts nested user.org map to Organization struct" do
      attrs = Keyword.put(valid_attrs(), :user, %{uid: "u1", org: %{uid: "org-1", name: "Acme"}})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.User{uid: "u1"} = event.user
      assert %OCSF.Organization{uid: "org-1", name: "Acme"} = event.user.org
    end

    test "casts nested actor.user map to User struct" do
      attrs = Keyword.put(valid_attrs(), :actor, %{user: %{uid: "actor-u1"}})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.Actor{} = event.actor
      assert %OCSF.User{uid: "actor-u1"} = event.actor.user
    end

    test "casts plain service map to Service struct" do
      attrs = Keyword.put(valid_attrs(), :service, %{name: "svc", uid: "s1"})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.Service{name: "svc", uid: "s1"} = event.service
    end

    test "casts plain dst_endpoint map to NetworkEndpoint struct" do
      attrs = Keyword.put(valid_attrs(), :dst_endpoint, %{hostname: "host.local"})
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert %OCSF.NetworkEndpoint{hostname: "host.local"} = event.dst_endpoint
    end

    test "cast_if passes through already-struct values" do
      user = %OCSF.User{uid: "u1", name: "Alice"}
      attrs = Keyword.put(valid_attrs(), :user, user)
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.user == user
    end

    test "cast_metadata passes through already-struct OCSF.Metadata" do
      meta = %OCSF.Metadata{
        uid: "m1",
        version: "1.8.0",
        product: %OCSF.Product{name: "Test"}
      }

      attrs = Keyword.put(valid_attrs(), :metadata, meta)
      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.metadata == meta
    end

    test "cast_product passes through already-struct OCSF.Product" do
      product = %OCSF.Product{name: "Test", feature: %OCSF.Feature{name: "F1"}}

      attrs =
        Keyword.put(valid_attrs(), :metadata, %{
          uid: "m1",
          version: "1.8.0",
          product: product
        })

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.metadata.product == product
    end

    test "cast_feature passes through already-struct OCSF.Feature" do
      feature = %OCSF.Feature{name: "F1", uid: "f1"}

      attrs =
        Keyword.put(valid_attrs(), :metadata, %{
          uid: "m1",
          version: "1.8.0",
          product: %{name: "Test", feature: feature}
        })

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.metadata.product.feature == feature
    end

    test "casts metadata map with nil product" do
      attrs =
        Keyword.put(valid_attrs(), :metadata, %{
          uid: "m1",
          version: "1.8.0",
          product: nil
        })

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.metadata.product == nil
    end

    test "casts metadata map with nil feature inside product map" do
      attrs =
        Keyword.put(valid_attrs(), :metadata, %{
          uid: "m1",
          version: "1.8.0",
          product: %{name: "Test", feature: nil}
        })

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.metadata.product.feature == nil
    end

    test "nil nested objects remain nil" do
      attrs =
        valid_attrs()
        |> Keyword.put(:actor, nil)
        |> Keyword.put(:http_request, nil)
        |> Keyword.put(:src_endpoint, nil)
        |> Keyword.put(:dst_endpoint, nil)
        |> Keyword.put(:service, nil)

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.actor == nil
      assert event.http_request == nil
      assert event.src_endpoint == nil
      assert event.dst_endpoint == nil
      assert event.service == nil
    end
  end

  describe "new/1 with string-keyed map" do
    test "creates event from string-keyed map" do
      attrs = %{
        "metadata" => %{
          "uid" => "test-uid",
          "version" => "1.8.0",
          "product" => %{"name" => "Test"}
        },
        "time" => ~U[2026-04-15 10:00:00Z],
        "category_uid" => 3,
        "class_uid" => 3002,
        "type_uid" => 300_201,
        "activity_id" => 1,
        "severity_id" => 1,
        "status_id" => 1,
        "user" => %{"uid" => "u1"}
      }

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.class_uid == 3002
      assert event.metadata.uid == "test-uid"
      assert event.metadata.product.name == "Test"
      assert event.user.uid == "u1"
    end

    test "casts string-keyed metadata nested objects" do
      attrs = %{
        "metadata" => %{
          "uid" => "test-uid",
          "version" => "1.8.0",
          "product" => %{
            "name" => "Test",
            "feature" => %{"name" => "Login", "uid" => "f1", "version" => "1.0"},
            "vendor_name" => "Vendor",
            "uid" => "p1",
            "version" => "3.0"
          },
          "profiles" => ["host"],
          "event_code" => "auth:logon",
          "correlation_uid" => "corr-1",
          "trace_uid" => "trace-1",
          "span_uid" => "span-1"
        },
        "time" => ~U[2026-04-15 10:00:00Z],
        "category_uid" => 3,
        "class_uid" => 3002,
        "type_uid" => 300_201,
        "activity_id" => 1,
        "severity_id" => 1,
        "status_id" => 1,
        "user" => %{"uid" => "u1"}
      }

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.metadata.product.feature.name == "Login"
      assert event.metadata.profiles == ["host"]
      assert event.metadata.correlation_uid == "corr-1"
    end

    test "casts string-keyed event-level nested objects" do
      attrs = %{
        "metadata" => %{
          "uid" => "test-uid",
          "version" => "1.8.0",
          "product" => %{"name" => "Test"}
        },
        "time" => ~U[2026-04-15 10:00:00Z],
        "category_uid" => 3,
        "class_uid" => 3002,
        "type_uid" => 300_201,
        "activity_id" => 1,
        "severity_id" => 1,
        "status_id" => 1,
        "status_detail" => "ok",
        "auth_protocol_id" => 5,
        "user" => %{"uid" => "u1", "org" => %{"uid" => "org-1", "name" => "Acme"}},
        "actor" => %{"user" => %{"uid" => "a-u1"}, "session" => "s1"},
        "http_request" => %{"url" => "https://test.com"},
        "src_endpoint" => %{"ip" => "10.0.0.1"},
        "dst_endpoint" => %{"hostname" => "dst.example.com"},
        "service" => %{"name" => "svc"},
        "raw_data" => "raw",
        "unmapped" => %{"k" => "v"}
      }

      assert {:ok, event} = OCSF.Event.new(attrs)
      assert event.user.org.uid == "org-1"
      assert event.actor.user.uid == "a-u1"
      assert event.http_request.url == "https://test.com"
      assert event.service.name == "svc"
      assert event.raw_data == "raw"
      assert event.unmapped == %{"k" => "v"}
      assert event.status_detail == "ok"
      assert event.auth_protocol_id == 5
    end
  end

  describe "from_map/1" do
    test "delegates to OCSF.Deserializer.from_map/1" do
      attrs = Map.new(valid_attrs())
      {:ok, event} = OCSF.Event.new(attrs)
      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.Event.from_map(map)
      assert restored.class_uid == event.class_uid
    end
  end
end
