defmodule OCSF.TestTelemetryHandler do
  @moduledoc false

  def handle_event(event_name, measurements, metadata, %{pid: pid}) do
    send(pid, {:telemetry, event_name, measurements, metadata})
  end
end
