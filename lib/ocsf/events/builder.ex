defmodule OCSF.Events.Builder do
  @moduledoc false
  # Shared internal builder behind every `OCSF.Events.*` module.
  #
  # Each class module owns its `@class_uid`, `@category_uid`, one public
  # function per activity and the map of class-specific attributes; this
  # module owns everything else: option resolution (severity, status,
  # time, correlation), metadata assembly, construction, validation,
  # event-code derivation and telemetry.

  @doc """
  Build, validate and instrument an event for `class_uid`.

  `class_attrs` holds the attributes specific to the class (e.g.
  `%{entity: opts[:entity]}`); they are merged over the common ones.
  """
  @spec build(pos_integer, pos_integer, non_neg_integer, keyword, map) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def build(class_uid, category_uid, activity_id, opts, class_attrs) do
    attrs =
      Map.merge(
        %{
          metadata: build_metadata(opts),
          time: opts[:time] || DateTime.utc_now(),
          category_uid: category_uid,
          class_uid: class_uid,
          type_uid: class_uid * 100 + activity_id,
          activity_id: activity_id,
          severity_id: resolve_severity(opts[:severity]),
          status_id: resolve_status(opts[:status]),
          status_detail: opts[:status_detail],
          actor: opts[:actor],
          http_request: opts[:http_request],
          src_endpoint: opts[:src_endpoint],
          dst_endpoint: opts[:dst_endpoint],
          raw_data: opts[:raw_data],
          unmapped: opts[:unmapped]
        },
        class_attrs
      )

    with {:ok, event} <- OCSF.Event.new(attrs),
         {:ok, event} <- OCSF.validate(event) do
      event = resolve_event_code(event, opts)
      OCSF.Telemetry.event_new(class_uid, activity_id)
      {:ok, event}
    else
      {:error, error} ->
        OCSF.Telemetry.event_invalid(error.reason, error.path, class_uid)
        {:error, error}
    end
  end

  # Top-level shortcut keys (`:event_code`, `:correlation_uid`,
  # `:trace_uid`, `:span_uid`) take precedence over the same keys inside
  # `:metadata`; the correlation scope is the last fallback.
  #
  # A `:metadata` value that is neither a map nor a struct is passed
  # through untouched so that `OCSF.validate/1` reports the type mismatch.
  defp build_metadata(opts) do
    case opts[:metadata] do
      nil -> assemble_metadata(%{}, opts)
      %OCSF.Metadata{} = m -> assemble_metadata(Map.from_struct(m), opts)
      %{} = m -> assemble_metadata(m, opts)
      other -> other
    end
  end

  defp assemble_metadata(base, opts) do
    %{
      uid: get_base(base, :uid) || OCSF.UUID.v7_string(),
      version: OCSF.version(),
      product: get_base(base, :product) || %OCSF.Product{},
      profiles: get_base(base, :profiles) || [],
      event_code: shortcut(opts, base, :event_code),
      correlation_uid: shortcut(opts, base, :correlation_uid) || OCSF.Correlation.current(),
      trace_uid: shortcut(opts, base, :trace_uid),
      span_uid: shortcut(opts, base, :span_uid)
    }
  end

  defp shortcut(opts, base, key), do: opts[key] || get_base(base, key)
  defp get_base(base, key), do: base[key] || base[to_string(key)]

  defp resolve_event_code(event, opts) do
    cond do
      # Explicit event_code already set
      event.metadata.event_code != nil ->
        event

      # Format specified in opts
      format_name = opts[:event_code_format] ->
        apply_format(event, format_name)

      # Default format from config
      default = OCSF.EventCodeFormat.default_format() ->
        apply_format(event, default)

      true ->
        event
    end
  end

  defp apply_format(event, format_name) do
    case OCSF.EventCodeFormat.get(format_name) do
      nil ->
        event

      format ->
        code = OCSF.EventCodeFormat.generate(format, event)
        put_in(event.metadata.event_code, code)
    end
  end

  defp resolve_severity(nil), do: OCSF.Severity.uid(:Informational)
  defp resolve_severity(id) when is_integer(id), do: id
  defp resolve_severity(name) when is_atom(name), do: OCSF.Severity.uid(name) || 0

  defp resolve_status(nil), do: OCSF.Status.uid(:Unknown)
  defp resolve_status(id) when is_integer(id), do: id
  defp resolve_status(name) when is_atom(name), do: OCSF.Status.uid(name) || 0
end
