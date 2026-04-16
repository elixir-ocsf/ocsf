defmodule OCSF.TelemetryTest do
  use ExUnit.Case, async: false

  setup do
    ref = make_ref()
    test_pid = self()

    :telemetry.attach(
      "test-handler-#{inspect(ref)}",
      [:ocsf, :event, :new],
      fn event_name, measurements, metadata, _config ->
        send(test_pid, {:telemetry, event_name, measurements, metadata})
      end,
      nil
    )

    :telemetry.attach(
      "test-handler-invalid-#{inspect(ref)}",
      [:ocsf, :event, :invalid],
      fn event_name, measurements, metadata, _config ->
        send(test_pid, {:telemetry, event_name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-handler-#{inspect(ref)}")
      :telemetry.detach("test-handler-invalid-#{inspect(ref)}")
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
      test_pid = self()

      :telemetry.attach(
        "test-emit-handler-#{inspect(ref)}",
        [:ocsf, :custom, :test],
        fn event_name, measurements, metadata, _config ->
          send(test_pid, {:telemetry, event_name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach("test-emit-handler-#{inspect(ref)}")
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
