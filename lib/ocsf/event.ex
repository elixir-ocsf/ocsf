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
  - `:entity` — `%OCSF.Entity{} | nil`. Required for Entity Management (3004).
  - `:group` — `%OCSF.Group{} | nil`. Required for Group Management (3006).
  - `:api` — `%OCSF.Api{} | nil`. Required for API Activity (6003).
  - `:privileges` — `[String.t()] | nil`. List of assigned/revoked
    privileges. Required for User Access Management (3005).
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
          entity: OCSF.Entity.t() | nil,
          group: OCSF.Group.t() | nil,
          api: OCSF.Api.t() | nil,
          privileges: [String.t()] | nil,
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
    :entity,
    :group,
    :api,
    :privileges,
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
      metadata: cast_metadata(get_attr(attrs, :metadata)),
      time: get_attr(attrs, :time),
      category_uid: get_attr(attrs, :category_uid),
      class_uid: get_attr(attrs, :class_uid),
      type_uid: get_attr(attrs, :type_uid),
      activity_id: get_attr(attrs, :activity_id),
      severity_id: get_attr(attrs, :severity_id),
      status_id: get_attr(attrs, :status_id),
      status_detail: get_attr(attrs, :status_detail),
      auth_protocol_id: get_attr(attrs, :auth_protocol_id),
      actor: cast_if(get_attr(attrs, :actor), OCSF.Actor),
      user: cast_if(get_attr(attrs, :user), OCSF.User),
      entity: cast_if(get_attr(attrs, :entity), OCSF.Entity),
      group: cast_if(get_attr(attrs, :group), OCSF.Group),
      api: cast_if(get_attr(attrs, :api), OCSF.Api),
      privileges: get_attr(attrs, :privileges),
      http_request: cast_if(get_attr(attrs, :http_request), OCSF.HttpRequest),
      src_endpoint: cast_if(get_attr(attrs, :src_endpoint), OCSF.NetworkEndpoint),
      dst_endpoint: cast_if(get_attr(attrs, :dst_endpoint), OCSF.NetworkEndpoint),
      service: cast_if(get_attr(attrs, :service), OCSF.Service),
      raw_data: get_attr(attrs, :raw_data),
      unmapped: get_attr(attrs, :unmapped)
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
      uid: get_attr(m, :uid),
      version: get_attr(m, :version),
      product: cast_product(get_attr(m, :product)),
      profiles: get_attr(m, :profiles) || [],
      event_code: get_attr(m, :event_code),
      correlation_uid: get_attr(m, :correlation_uid),
      trace_uid: get_attr(m, :trace_uid),
      span_uid: get_attr(m, :span_uid)
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

  defp get_attr(map, key), do: map[key] || map[to_string(key)]

  defp cast_if(nil, _mod), do: nil
  defp cast_if(%{__struct__: mod} = s, mod), do: s

  defp cast_if(%{} = m, mod) do
    fields = mod.__struct__() |> Map.from_struct() |> Map.keys()

    casted =
      for key <- fields, into: %{} do
        val = m[key] || m[to_string(key)]
        {key, val}
      end

    struct(mod, cast_nested(mod, casted))
  end

  # Recursively cast the single nested object each parent struct carries.
  defp cast_nested(OCSF.User, casted), do: maybe_cast(casted, :org, OCSF.Organization)
  defp cast_nested(OCSF.Actor, casted), do: maybe_cast(casted, :user, OCSF.User)
  defp cast_nested(OCSF.Api, casted), do: maybe_cast(casted, :service, OCSF.Service)
  defp cast_nested(_mod, casted), do: casted

  defp maybe_cast(casted, key, mod) do
    val = casted[key]

    if is_map(val) and not is_struct(val, mod) do
      Map.put(casted, key, cast_if(val, mod))
    else
      casted
    end
  end
end
