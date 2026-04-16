defmodule OCSF.Event do
  @moduledoc """
  OCSF event struct.

  Represents a single OCSF-compliant security event. Mirrors the
  [OCSF 1.8 base event](https://schema.ocsf.io/1.8.0/base_event) with
  nested object structs for `metadata`, `user`, `http_request`, etc.

  Use per-class builders (`OCSF.Events.Authentication`) rather than
  `new/1` directly. The low-level constructor is public for replay
  tooling and deserialization.

  ## Fields

  - `:metadata` — `%OCSF.Metadata{}` (required). Carries `uid`,
    `version`, `product`, `event_code`, `correlation_uid`.
  - `:time` — `DateTime.t()` (required). UTC event timestamp.
  - `:category_uid` — integer. Top-level OCSF category.
  - `:class_uid` — integer. OCSF event class.
  - `:type_uid` — integer. `class_uid * 100 + activity_id`.
  - `:activity_id` — integer. Class-scoped activity.
  - `:severity_id` — integer. Severity level.
  - `:status_id` — integer. Event status.
  - `:status_detail` — `String.t() | nil`. Free-form detail.
  - `:auth_protocol_id` — `integer | nil`. Auth protocol.
  - `:user` — `%OCSF.User{} | nil`.
  - `:actor` — `%OCSF.Actor{} | nil`.
  - `:http_request` — `%OCSF.HttpRequest{} | nil`.
  - `:src_endpoint` — `%OCSF.NetworkEndpoint{} | nil`.
  - `:dst_endpoint` — `%OCSF.NetworkEndpoint{} | nil`.
  - `:service` — `%OCSF.Service{} | nil`.
  - `:raw_data` — `String.t() | nil`. Raw event payload.
  - `:unmapped` — `map | nil`. Extension escape hatch.

  See `OCSF.validate/1`, `OCSF.to_map/1`, `OCSF.Events.Authentication`.
  """

  @type t :: %__MODULE__{
          metadata: OCSF.Metadata.t(),
          time: DateTime.t(),
          category_uid: integer,
          class_uid: integer,
          type_uid: integer,
          activity_id: integer,
          severity_id: integer,
          status_id: integer,
          status_detail: String.t() | nil,
          auth_protocol_id: integer | nil,
          actor: OCSF.Actor.t() | nil,
          user: OCSF.User.t() | nil,
          http_request: OCSF.HttpRequest.t() | nil,
          src_endpoint: OCSF.NetworkEndpoint.t() | nil,
          dst_endpoint: OCSF.NetworkEndpoint.t() | nil,
          service: OCSF.Service.t() | nil,
          raw_data: String.t() | nil,
          unmapped: map | nil
        }

  defstruct [
    :metadata,
    :time,
    :category_uid,
    :class_uid,
    :type_uid,
    :activity_id,
    :severity_id,
    :status_id,
    :status_detail,
    :auth_protocol_id,
    :actor,
    :user,
    :http_request,
    :src_endpoint,
    :dst_endpoint,
    :service,
    :raw_data,
    :unmapped
  ]

  @doc """
  Build an event from a keyword list or map.

  This is the low-level constructor. Prefer per-class builders
  (`OCSF.Events.Authentication.logon/1`) which auto-resolve class,
  category, type, and activity fields.

  Casts plain maps to their OCSF struct equivalents for nested objects.
  Does NOT run validation — call `OCSF.validate/1` on the result.

  ## Examples

      iex> {:ok, event} = OCSF.Event.new(
      ...>   metadata: %OCSF.Metadata{
      ...>     uid: "test-uid",
      ...>     version: "1.8.0",
      ...>     product: %OCSF.Product{name: "Test"}
      ...>   },
      ...>   time: ~U[2026-04-15 10:00:00Z],
      ...>   category_uid: 3,
      ...>   class_uid: 3002,
      ...>   type_uid: 300201,
      ...>   activity_id: 1,
      ...>   severity_id: 1,
      ...>   status_id: 1
      ...> )
      iex> event.class_uid
      3002
  """
  @spec new(keyword | map) :: {:ok, t} | {:error, OCSF.Error.t()}
  def new(attrs) when is_list(attrs) do
    attrs |> Map.new() |> new()
  end

  def new(attrs) when is_map(attrs) do
    event = %__MODULE__{
      metadata: cast_metadata(attrs[:metadata] || attrs["metadata"]),
      time: attrs[:time] || attrs["time"],
      category_uid: attrs[:category_uid] || attrs["category_uid"],
      class_uid: attrs[:class_uid] || attrs["class_uid"],
      type_uid: attrs[:type_uid] || attrs["type_uid"],
      activity_id: attrs[:activity_id] || attrs["activity_id"],
      severity_id: attrs[:severity_id] || attrs["severity_id"],
      status_id: attrs[:status_id] || attrs["status_id"],
      status_detail: attrs[:status_detail] || attrs["status_detail"],
      auth_protocol_id: attrs[:auth_protocol_id] || attrs["auth_protocol_id"],
      actor: cast_if(attrs[:actor] || attrs["actor"], OCSF.Actor),
      user: cast_if(attrs[:user] || attrs["user"], OCSF.User),
      http_request: cast_if(attrs[:http_request] || attrs["http_request"], OCSF.HttpRequest),
      src_endpoint: cast_if(attrs[:src_endpoint] || attrs["src_endpoint"], OCSF.NetworkEndpoint),
      dst_endpoint: cast_if(attrs[:dst_endpoint] || attrs["dst_endpoint"], OCSF.NetworkEndpoint),
      service: cast_if(attrs[:service] || attrs["service"], OCSF.Service),
      raw_data: attrs[:raw_data] || attrs["raw_data"],
      unmapped: attrs[:unmapped] || attrs["unmapped"]
    }

    {:ok, event}
  end

  @doc """
  Reconstruct an event from a nested OCSF map.

  Accepts the map shape produced by `OCSF.to_map/1`. Runs validation
  after construction. Provides the round-trip guarantee:
  `event |> OCSF.to_map() |> OCSF.Event.from_map()` returns
  `{:ok, ^event}` (modulo nil-omitted fields).

  Delegates to `OCSF.Deserializer.from_map/1`.
  """
  @spec from_map(map) :: {:ok, t} | {:error, OCSF.Error.t()}
  def from_map(map) when is_map(map), do: OCSF.Deserializer.from_map(map)

  defp cast_metadata(%OCSF.Metadata{} = m), do: m
  defp cast_metadata(nil), do: nil

  defp cast_metadata(%{} = m) do
    %OCSF.Metadata{
      uid: m[:uid] || m["uid"],
      version: m[:version] || m["version"],
      product: cast_product(m[:product] || m["product"]),
      profiles: m[:profiles] || m["profiles"] || [],
      event_code: m[:event_code] || m["event_code"],
      correlation_uid: m[:correlation_uid] || m["correlation_uid"],
      trace_uid: m[:trace_uid] || m["trace_uid"],
      span_uid: m[:span_uid] || m["span_uid"]
    }
  end

  defp cast_product(%OCSF.Product{} = p), do: p
  defp cast_product(nil), do: nil

  defp cast_product(%{} = p) do
    %OCSF.Product{
      name: p[:name] || p["name"],
      vendor_name: p[:vendor_name] || p["vendor_name"],
      feature: cast_feature(p[:feature] || p["feature"]),
      uid: p[:uid] || p["uid"],
      version: p[:version] || p["version"]
    }
  end

  defp cast_feature(%OCSF.Feature{} = f), do: f
  defp cast_feature(nil), do: nil

  defp cast_feature(%{} = f) do
    %OCSF.Feature{
      name: f[:name] || f["name"],
      uid: f[:uid] || f["uid"],
      version: f[:version] || f["version"]
    }
  end

  defp cast_if(nil, _mod), do: nil
  defp cast_if(%{__struct__: mod} = s, mod), do: s

  defp cast_if(%{} = m, mod) do
    fields = mod.__struct__() |> Map.from_struct() |> Map.keys()

    casted =
      for key <- fields, into: %{} do
        val = m[key] || m[to_string(key)]
        {key, val}
      end

    # Handle nested org in User
    casted =
      if mod == OCSF.User and is_map(casted[:org]) and
           not is_struct(casted[:org], OCSF.Organization) do
        Map.put(casted, :org, cast_if(casted[:org], OCSF.Organization))
      else
        casted
      end

    # Handle nested user in Actor
    casted =
      if mod == OCSF.Actor and is_map(casted[:user]) and not is_struct(casted[:user], OCSF.User) do
        Map.put(casted, :user, cast_if(casted[:user], OCSF.User))
      else
        casted
      end

    struct(mod, casted)
  end
end
