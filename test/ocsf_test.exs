defmodule OCSFTest do
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
        user: %OCSF.User{uid: "u1"}
      )

    {:ok, event} = OCSF.Event.new(attrs)
    event
  end

  describe "version/0" do
    test "returns OCSF 1.9.0" do
      assert OCSF.version() == "1.9.0"
    end
  end

  describe "to_map/1" do
    test "delegates to OCSF.Serializer.to_map/1" do
      event = valid_event()
      map = OCSF.to_map(event)
      assert map[:class_uid] == 3002
    end
  end

  describe "to_json/1" do
    test "returns iodata that decodes to correct JSON" do
      event = valid_event()
      iodata = OCSF.to_json(event)
      json = IO.iodata_to_binary(iodata)
      decoded = Jason.decode!(json)
      assert decoded["class_uid"] == 3002
      assert decoded["metadata"]["uid"] == "test-uid"
    end
  end

  describe "from_map/1" do
    test "reconstructs event from map" do
      event = valid_event()
      map = OCSF.to_map(event)
      assert {:ok, restored} = OCSF.from_map(map)
      assert restored.class_uid == 3002
      assert restored.user.uid == "u1"
    end
  end

  describe "redact/2" do
    test "applies policy to event" do
      event = %{
        valid_event()
        | user: %OCSF.User{uid: "u1", name: "Alice", email_addr: "alice@test.com"}
      }

      policy = %OCSF.Policy{
        deny: [:contact, :identity],
        allow: [:identifier, :tenant, :taxonomic]
      }

      redacted = OCSF.redact(event, policy)
      assert redacted.user.uid == "u1"
      assert redacted.user.name == nil
      assert redacted.user.email_addr == nil
    end
  end

  describe "validate/1" do
    test "returns {:ok, event} for valid event" do
      assert {:ok, _} = OCSF.validate(valid_event())
    end

    test "returns {:error, _} for invalid event (missing metadata.uid)" do
      event = put_in(valid_event().metadata.uid, nil)
      assert {:error, %OCSF.Error{reason: :missing, path: "metadata.uid"}} = OCSF.validate(event)
    end

    test "returns {:error, _} for empty metadata.uid" do
      event = put_in(valid_event().metadata.uid, "")
      assert {:error, %OCSF.Error{reason: :missing, path: "metadata.uid"}} = OCSF.validate(event)
    end

    test "returns {:error, _} for missing metadata.version" do
      event = put_in(valid_event().metadata.version, nil)

      assert {:error, %OCSF.Error{reason: :invalid, path: "metadata.version"}} =
               OCSF.validate(event)
    end

    test "returns {:error, _} for invalid class_uid" do
      event = %{valid_event() | class_uid: 9999}

      assert {:error, %OCSF.Error{reason: :invalid, path: "class_uid"}} = OCSF.validate(event)
    end

    test "returns {:error, _} for metadata without version key" do
      # Construct event with metadata as a plain map lacking :version key
      event = valid_event()
      # Replace metadata with a map that has uid but no version key
      event = %{event | metadata: %{uid: "test-uid", product: %OCSF.Product{name: "Test"}}}

      assert {:error, %OCSF.Error{reason: :missing, path: "metadata.version"}} =
               OCSF.validate(event)
    end

    test "returns {:error, _} for nil metadata" do
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

      assert {:error, %OCSF.Error{reason: :missing}} = OCSF.validate(event)
    end
  end
end
