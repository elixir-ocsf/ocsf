defmodule OCSF.Telemetry do
  @moduledoc """
  Telemetry event definitions and metrics helpers.

  Defines the telemetry events emitted by the library and provides
  `metrics/0` returning a list of `Telemetry.Metrics` definitions
  ready to hand to a consumer's metrics supervisor or OTel exporter.

  ## Events emitted

  | Event                        | Measurements             | Metadata                              |
  |------------------------------|--------------------------|---------------------------------------|
  | `[:ocsf, :event, :new]`      | `%{count: 1}`            | `%{class_uid, activity_id}`           |
  | `[:ocsf, :event, :invalid]`  | `%{count: 1}`            | `%{reason, path, class_uid}`          |
  | `[:ocsf, :redact, :drop]`    | `%{count: 1}`            | `%{path, class, sink}`                |
  | `[:ocsf, :sink, :write]`     | `%{count, duration_us}`  | `%{sink, result}`                     |
  | `[:ocsf, :sink, :health]`    | `%{transitions: 1}`      | `%{sink, from, to}`                   |

  See `OCSF.Sink`, `OCSF.Policy`.
  """

  @doc """
  Emit a telemetry event.
  """
  @spec emit(list(atom), map, map) :: :ok
  def emit(event_name, measurements, metadata \\ %{}) do
    :telemetry.execute(event_name, measurements, metadata)
  end

  @doc """
  Emit a `[:ocsf, :event, :new]` event.
  """
  @spec event_new(integer, integer) :: :ok
  def event_new(class_uid, activity_id) do
    emit([:ocsf, :event, :new], %{count: 1}, %{
      class_uid: class_uid,
      activity_id: activity_id
    })
  end

  @doc """
  Emit a `[:ocsf, :event, :invalid]` event.
  """
  @spec event_invalid(atom, String.t(), integer | nil) :: :ok
  def event_invalid(reason, path, class_uid \\ nil) do
    emit([:ocsf, :event, :invalid], %{count: 1}, %{
      reason: reason,
      path: path,
      class_uid: class_uid
    })
  end
end
