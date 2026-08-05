defmodule OCSF.Serializer do
  @moduledoc """
  Serialization helpers for OCSF events and nested objects.

  Converts `%OCSF.Event{}` and nested structs into OCSF-compliant
  nested maps. Resolves enum UIDs to their human-readable `_name`
  labels per OCSF convention.

  Prefer `OCSF.to_map/1` over calling this module directly.

  See `OCSF.Event`, `OCSF.Metadata`.
  """

  @doc """
  Convert an `%OCSF.Event{}` to an OCSF-compliant nested map.

  Nil fields are omitted. Integer UIDs are emitted as-is; their
  corresponding `_name` labels are added alongside.
  """
  @spec to_map(OCSF.Event.t()) :: map
  def to_map(%OCSF.Event{} = event) do
    %{}
    |> put_not_nil(:metadata, serialize_metadata(event.metadata))
    |> put_not_nil(:time, serialize_time(event.time))
    |> Map.put(:category_uid, event.category_uid)
    |> put_name(:category_name, OCSF.Category.name(event.category_uid))
    |> Map.put(:class_uid, event.class_uid)
    |> put_name(:class_name, OCSF.Class.name(event.class_uid))
    |> Map.put(:type_uid, event.type_uid)
    |> Map.put(:activity_id, event.activity_id)
    |> put_name(:activity_name, OCSF.Activity.label(event.class_uid, event.activity_id))
    |> Map.put(:severity_id, event.severity_id)
    |> put_name(:severity, OCSF.Severity.name(event.severity_id))
    |> Map.put(:status_id, event.status_id)
    |> put_name(:status, OCSF.Status.name(event.status_id))
    |> put_not_nil(:status_detail, event.status_detail)
    |> put_not_nil(:auth_protocol_id, event.auth_protocol_id)
    |> put_auth_protocol_name(event.auth_protocol_id)
    |> put_not_nil(:actor, serialize_actor(event.actor))
    |> put_not_nil(:user, serialize_user(event.user))
    |> put_not_nil(:entity, serialize_entity(event.entity))
    |> put_not_nil(:group, serialize_group(event.group))
    |> put_not_nil(:api, serialize_api(event.api))
    |> put_privileges(event.privileges)
    |> put_not_nil(:http_request, serialize_http_request(event.http_request))
    |> put_not_nil(:src_endpoint, serialize_endpoint(event.src_endpoint))
    |> put_not_nil(:dst_endpoint, serialize_endpoint(event.dst_endpoint))
    |> put_not_nil(:service, serialize_service(event.service))
    |> put_not_nil(:raw_data, event.raw_data)
    |> put_not_nil(:unmapped, event.unmapped)
  end

  defp serialize_metadata(nil), do: nil

  defp serialize_metadata(%OCSF.Metadata{} = m) do
    %{}
    |> put_not_nil(:uid, m.uid)
    |> put_not_nil(:version, m.version)
    |> put_not_nil(:product, serialize_product(m.product))
    |> put_not_empty_list(:profiles, m.profiles)
    |> put_not_nil(:event_code, m.event_code)
    |> put_not_nil(:correlation_uid, m.correlation_uid)
    |> put_not_nil(:trace_uid, m.trace_uid)
    |> put_not_nil(:span_uid, m.span_uid)
  end

  defp serialize_product(nil), do: nil

  defp serialize_product(%OCSF.Product{} = p) do
    %{}
    |> put_not_nil(:name, p.name)
    |> put_not_nil(:vendor_name, p.vendor_name)
    |> put_not_nil(:feature, serialize_feature(p.feature))
    |> put_not_nil(:uid, p.uid)
    |> put_not_nil(:version, p.version)
  end

  defp serialize_feature(nil), do: nil

  defp serialize_feature(%OCSF.Feature{} = f) do
    %{}
    |> put_not_nil(:name, f.name)
    |> put_not_nil(:uid, f.uid)
    |> put_not_nil(:version, f.version)
  end

  defp serialize_user(nil), do: nil

  defp serialize_user(%OCSF.User{} = u) do
    %{}
    |> put_not_nil(:uid, u.uid)
    |> put_not_nil(:name, u.name)
    |> put_not_nil(:email_addr, u.email_addr)
    |> put_not_nil(:org, serialize_org(u.org))
    |> put_not_nil(:type_id, u.type_id)
  end

  defp serialize_org(nil), do: nil

  defp serialize_org(%OCSF.Organization{} = o) do
    %{}
    |> put_not_nil(:uid, o.uid)
    |> put_not_nil(:name, o.name)
  end

  defp serialize_entity(nil), do: nil

  defp serialize_entity(%OCSF.Entity{} = e) do
    %{}
    |> put_not_nil(:name, e.name)
    |> put_not_nil(:type, e.type)
    |> put_not_nil(:type_id, e.type_id)
    |> put_not_nil(:uid, e.uid)
    |> put_not_nil(:email, e.email)
  end

  defp serialize_group(nil), do: nil

  defp serialize_group(%OCSF.Group{} = g) do
    %{}
    |> put_not_nil(:name, g.name)
    |> put_not_nil(:uid, g.uid)
    |> put_not_nil(:type, g.type)
    |> put_not_nil(:desc, g.desc)
  end

  defp serialize_api(nil), do: nil

  defp serialize_api(%OCSF.Api{} = a) do
    %{}
    |> put_not_nil(:operation, a.operation)
    |> put_not_nil(:version, a.version)
    |> put_not_nil(:service, serialize_service(a.service))
  end

  defp serialize_actor(nil), do: nil

  defp serialize_actor(%OCSF.Actor{} = a) do
    %{}
    |> put_not_nil(:user, serialize_user(a.user))
    |> put_not_nil(:session, a.session)
  end

  defp serialize_http_request(nil), do: nil

  defp serialize_http_request(%OCSF.HttpRequest{} = r) do
    %{}
    |> put_not_nil(:url, r.url)
    |> put_not_nil(:user_agent, r.user_agent)
    |> put_not_nil(:http_method, r.http_method)
  end

  defp serialize_endpoint(nil), do: nil

  defp serialize_endpoint(%OCSF.NetworkEndpoint{} = e) do
    %{}
    |> put_not_nil(:ip, serialize_ip(e.ip))
    |> put_not_nil(:port, e.port)
    |> put_not_nil(:hostname, e.hostname)
  end

  defp serialize_service(nil), do: nil

  defp serialize_service(%OCSF.Service{} = s) do
    %{}
    |> put_not_nil(:name, s.name)
    |> put_not_nil(:uid, s.uid)
    |> put_not_nil(:version, s.version)
  end

  defp serialize_ip(nil), do: nil
  defp serialize_ip(ip) when is_binary(ip), do: ip

  defp serialize_ip(ip) when is_tuple(ip) do
    ip |> :inet.ntoa() |> to_string()
  end

  defp serialize_time(nil), do: nil
  defp serialize_time(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp put_not_nil(map, _key, nil), do: map
  defp put_not_nil(map, key, value), do: Map.put(map, key, value)

  defp put_not_empty_list(map, _key, []), do: map
  defp put_not_empty_list(map, key, list), do: Map.put(map, key, list)

  defp put_privileges(map, nil), do: map
  defp put_privileges(map, []), do: map
  defp put_privileges(map, list) when is_list(list), do: Map.put(map, :privileges, list)

  defp put_name(map, _key, nil), do: map
  defp put_name(map, key, name), do: Map.put(map, key, Atom.to_string(name))

  defp put_auth_protocol_name(map, nil), do: map

  defp put_auth_protocol_name(map, id) do
    case OCSF.AuthProtocol.name(id) do
      nil -> map
      name -> Map.put(map, :auth_protocol, Atom.to_string(name))
    end
  end
end
