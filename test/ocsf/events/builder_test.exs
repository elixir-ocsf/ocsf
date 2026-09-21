defmodule OCSF.Events.BuilderTest do
  # Covers the behaviour shared by every OCSF.Events.* module once:
  # option resolution, metadata precedence, event-code derivation and
  # telemetry. Per-class tests only cover class-specific attributes.
  use ExUnit.Case, async: false

  alias OCSF.{Error, Metadata, Product}
  alias OCSF.Events.Builder

  @class_uid 3004
  @category_uid 3

  setup do
    ref = make_ref()
    handler_new = "builder-new-#{inspect(ref)}"
    handler_invalid = "builder-invalid-#{inspect(ref)}"

    :telemetry.attach(
      handler_new,
      [:ocsf, :event, :new],
      &OCSF.TestTelemetryHandler.handle_event/4,
      %{pid: self()}
    )

    :telemetry.attach(
      handler_invalid,
      [:ocsf, :event, :invalid],
      &OCSF.TestTelemetryHandler.handle_event/4,
      %{pid: self()}
    )

    on_exit(fn ->
      :telemetry.detach(handler_new)
      :telemetry.detach(handler_invalid)
      Application.delete_env(:ocsf, :event_code)
    end)

    :ok
  end

  defp build(opts, class_attrs \\ %{entity: %{uid: "e1"}}) do
    Builder.build(@class_uid, @category_uid, 1, opts, class_attrs)
  end

  describe "common attributes" do
    test "derives category, class, type and activity from the arguments" do
      assert {:ok, event} = build([])
      assert event.category_uid == 3
      assert event.class_uid == 3004
      assert event.activity_id == 1
      assert event.type_uid == 300_401
    end

    test "defaults severity to Informational and status to Unknown" do
      assert {:ok, event} = build([])
      assert event.severity_id == OCSF.Severity.uid(:Informational)
      assert event.status_id == OCSF.Status.uid(:Unknown)
    end

    test "resolves severity and status atoms, passes integers through, unknown atom -> 0" do
      assert {:ok, event} = build(severity: :High, status: :Failure)
      assert event.severity_id == OCSF.Severity.uid(:High)
      assert event.status_id == OCSF.Status.uid(:Failure)

      assert {:ok, event} = build(severity: 4, status: 2)
      assert {4, 2} == {event.severity_id, event.status_id}

      assert {:ok, event} = build(severity: :Nope, status: :Nope)
      assert {0, 0} == {event.severity_id, event.status_id}
    end

    test "class attributes override the common ones" do
      assert {:ok, event} =
               build([status_detail: "common"], %{entity: %{uid: "e1"}, status_detail: "class"})

      assert event.status_detail == "class"
    end

    test "uses the given time, else now (UTC)" do
      time = ~U[2026-04-15 10:00:00Z]
      assert {:ok, %{time: ^time}} = build(time: time)

      assert {:ok, event} = build([])
      assert DateTime.diff(DateTime.utc_now(), event.time, :second) < 5
    end
  end

  describe "metadata" do
    test "generates a UUIDv7 uid, stamps the emitted version and a default product" do
      assert {:ok, event} = build([])

      assert String.match?(
               event.metadata.uid,
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$/
             )

      assert event.metadata.version == OCSF.version()
      assert %Product{} = event.metadata.product
      assert event.metadata.profiles == []
    end

    test "accepts a map, a string-keyed map or a %OCSF.Metadata{} struct" do
      product = %Product{name: "Test"}

      assert {:ok, e1} = build(metadata: %{uid: "m1", product: product, profiles: ["cloud"]})
      assert {:ok, e2} = build(metadata: %{"uid" => "m1", "product" => product})
      assert {:ok, e3} = build(metadata: %Metadata{uid: "m1", product: product})

      assert e1.metadata.uid == "m1" and e1.metadata.profiles == ["cloud"]
      assert e2.metadata.uid == "m1" and e2.metadata.product == product
      assert e3.metadata.uid == "m1" and e3.metadata.product == product
    end

    test "a metadata value that is not a map is reported, not raised" do
      assert {:error, %Error{reason: :type_mismatch, path: "metadata"}} = build(metadata: "1.9.0")
    end

    test "top-level shortcut keys win over the metadata map" do
      opts = [
        event_code: "top",
        correlation_uid: "corr-top",
        trace_uid: "trace-top",
        span_uid: "span-top",
        metadata: %{
          event_code: "meta",
          correlation_uid: "corr-meta",
          trace_uid: "trace-meta",
          span_uid: "span-meta"
        }
      ]

      assert {:ok, event} = build(opts)
      assert event.metadata.event_code == "top"
      assert event.metadata.correlation_uid == "corr-top"
      assert event.metadata.trace_uid == "trace-top"
      assert event.metadata.span_uid == "span-top"
    end

    test "metadata map keys are used when no shortcut is given" do
      opts = [metadata: %{event_code: "meta", correlation_uid: "corr-meta", trace_uid: "t"}]
      assert {:ok, event} = build(opts)
      assert event.metadata.event_code == "meta"
      assert event.metadata.correlation_uid == "corr-meta"
      assert event.metadata.trace_uid == "t"
    end

    test "correlation_uid falls back to the OCSF.Correlation scope" do
      OCSF.Correlation.with("corr-scope", fn ->
        assert {:ok, event} = build([])
        assert event.metadata.correlation_uid == "corr-scope"

        assert {:ok, event} = build(correlation_uid: "corr-explicit")
        assert event.metadata.correlation_uid == "corr-explicit"
      end)
    end
  end

  describe "event code derivation" do
    setup do
      Application.put_env(:ocsf, :event_code,
        default_format: :dflt,
        formats: %{
          dflt: %{fields: [[:class_name], [:activity_name]], separator: ":"},
          custom: %{fields: [[:class_name]], separator: "-"}
        }
      )

      :ok
    end

    test "an explicit event_code wins over any format" do
      assert {:ok, event} = build(event_code: "explicit", event_code_format: :custom)
      assert event.metadata.event_code == "explicit"
    end

    test "event_code_format from opts wins over the configured default" do
      assert {:ok, event} = build(event_code_format: :custom)
      assert event.metadata.event_code == "entity_management"
    end

    test "the configured default format applies otherwise" do
      assert {:ok, event} = build([])
      assert event.metadata.event_code == "entity_management:create"
    end

    test "an unknown format name leaves event_code nil" do
      Application.delete_env(:ocsf, :event_code)
      assert {:ok, event} = build(event_code_format: :nope)
      assert event.metadata.event_code == nil
    end

    test "no format at all leaves event_code nil" do
      Application.delete_env(:ocsf, :event_code)
      assert {:ok, event} = build([])
      assert event.metadata.event_code == nil
    end
  end

  describe "validation and telemetry" do
    test "a valid event emits [:ocsf, :event, :new]" do
      assert {:ok, _} = build([])

      assert_receive {:telemetry, [:ocsf, :event, :new], %{count: 1},
                      %{class_uid: 3004, activity_id: 1}}
    end

    test "an invalid event returns the error and emits [:ocsf, :event, :invalid]" do
      assert {:error, %Error{reason: :missing, path: "entity"}} = build([], %{entity: nil})

      assert_receive {:telemetry, [:ocsf, :event, :invalid], %{count: 1},
                      %{reason: :missing, path: "entity", class_uid: 3004}}

      refute_receive {:telemetry, [:ocsf, :event, :new], _, _}
    end
  end
end
