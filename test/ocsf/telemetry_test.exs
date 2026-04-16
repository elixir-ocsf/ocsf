defmodule OCSF.TelemetryTest do
  use ExUnit.Case, async: false

  setup do
    ref = make_ref()
    handler_id_new = "test-handler-new-#{inspect(ref)}"
    handler_id_invalid = "test-handler-invalid-#{inspect(ref)}"

    :telemetry.attach(
      handler_id_new,
      [:ocsf, :event, :new],
      &OCSF.TestTelemetryHandler.handle_event/4,
      %{pid: self()}
    )

    :telemetry.attach(
      handler_id_invalid,
      [:ocsf, :event, :invalid],
      &OCSF.TestTelemetryHandler.handle_event/4,
      %{pid: self()}
    )

    on_exit(fn ->
      :telemetry.detach(handler_id_new)
      :telemetry.detach(handler_id_invalid)
    end)

    :ok
  end

  describe "event_new/2" do
    test "emits [:ocsf, :event, :new] telemetry event" do
      OCSF.Telemetry.event_new(3002, 1)

      assert_receive {:telemetry, [:ocsf, :event, :new], %{count: 1},
                      %{class_uid: 3002, activity_id: 1}}
    end
  end

  describe "event_invalid/3" do
    test "emits [:ocsf, :event, :invalid] telemetry event" do
      OCSF.Telemetry.event_invalid(:missing, "user", 3002)

      assert_receive {:telemetry, [:ocsf, :event, :invalid], %{count: 1},
                      %{reason: :missing, path: "user", class_uid: 3002}}
    end

    test "emits [:ocsf, :event, :invalid] with nil class_uid by default" do
      OCSF.Telemetry.event_invalid(:missing, "metadata.uid")

      assert_receive {:telemetry, [:ocsf, :event, :invalid], %{count: 1},
                      %{reason: :missing, path: "metadata.uid", class_uid: nil}}
    end
  end

  describe "emit/3" do
    setup do
      ref = make_ref()
      handler_id = "test-emit-handler-#{inspect(ref)}"

      :telemetry.attach(
        handler_id,
        [:ocsf, :custom, :test],
        &OCSF.TestTelemetryHandler.handle_event/4,
        %{pid: self()}
      )

      on_exit(fn ->
        :telemetry.detach(handler_id)
      end)

      :ok
    end

    test "emits arbitrary telemetry events with measurements and metadata" do
      assert :ok = OCSF.Telemetry.emit([:ocsf, :custom, :test], %{count: 42}, %{foo: "bar"})

      assert_receive {:telemetry, [:ocsf, :custom, :test], %{count: 42}, %{foo: "bar"}}
    end

    test "emits with default empty metadata when not provided" do
      assert :ok = OCSF.Telemetry.emit([:ocsf, :custom, :test], %{count: 1})

      assert_receive {:telemetry, [:ocsf, :custom, :test], %{count: 1}, %{}}
    end
  end
end
