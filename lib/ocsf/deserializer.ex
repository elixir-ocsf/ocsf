defmodule OCSF.Deserializer do
  @moduledoc """
  Deserialization from OCSF-compliant nested maps back to structs.

  Reconstructs an `%OCSF.Event{}` from the map shape `OCSF.to_map/1`
  produces. Resolves `_name` strings back to UIDs via enum modules.

  Prefer `OCSF.Event.from_map/1` over calling this module directly.

  See `OCSF.Serializer`, `OCSF.Event`.
  """

  @doc """
  Reconstruct an `%OCSF.Event{}` from a nested OCSF map.

  Accepts both atom-keyed and string-keyed maps (e.g. from
  `Jason.decode!/1`). Runs `OCSF.validate/1` after construction.
  """
  @spec from_map(map) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def from_map(map) when is_map(map) do
    attrs = %{
      metadata: parse_metadata(get(map, :metadata)),
      time: parse_time(get(map, :time)),
      category_uid: get(map, :category_uid),
      class_uid: get(map, :class_uid),
      type_uid: get(map, :type_uid),
      activity_id: get(map, :activity_id),
      severity_id: get(map, :severity_id),
      status_id: get(map, :status_id),
      status_detail: get(map, :status_detail),
      auth_protocol_id: get(map, :auth_protocol_id),
      actor: parse_if(get(map, :actor), &parse_actor/1),
      user: parse_if(get(map, :user), &parse_user/1),
      updated_user: parse_if(get(map, :updated_user), &parse_user/1),
      entity: parse_if(get(map, :entity), &parse_entity/1),
      group: parse_if(get(map, :group), &parse_group/1),
      groups: parse_list_if(get(map, :groups), &parse_group/1),
      iam_role: parse_if(get(map, :iam_role), &parse_iam_role/1),
      iam_roles: parse_list_if(get(map, :iam_roles), &parse_iam_role/1),
      updated_role: parse_if(get(map, :updated_role), &parse_iam_role/1),
      api: parse_if(get(map, :api), &parse_api/1),
      privileges: get(map, :privileges),
      resources: get(map, :resources),
      http_request: parse_if(get(map, :http_request), &parse_http_request/1),
      src_endpoint: parse_if(get(map, :src_endpoint), &parse_endpoint/1),
      dst_endpoint: parse_if(get(map, :dst_endpoint), &parse_endpoint/1),
      service: parse_if(get(map, :service), &parse_service/1),
      raw_data: get(map, :raw_data),
      unmapped: get(map, :unmapped)
    }

    with {:ok, event} <- OCSF.Event.new(attrs) do
      OCSF.validate(event)
    end
  end

  defp parse_metadata(nil), do: nil

  defp parse_metadata(m) do
    %OCSF.Metadata{
      uid: get(m, :uid),
      version: get(m, :version),
      product: parse_if(get(m, :product), &parse_product/1),
      profiles: get(m, :profiles) || [],
      event_code: get(m, :event_code),
      correlation_uid: get(m, :correlation_uid),
      trace_uid: get(m, :trace_uid),
      span_uid: get(m, :span_uid)
    }
  end

  defp parse_product(p) do
    %OCSF.Product{
      name: get(p, :name),
      vendor_name: get(p, :vendor_name),
      feature: parse_if(get(p, :feature), &parse_feature/1),
      uid: get(p, :uid),
      version: get(p, :version)
    }
  end

  defp parse_feature(f) do
    %OCSF.Feature{
      name: get(f, :name),
      uid: get(f, :uid),
      version: get(f, :version)
    }
  end

  defp parse_user(u) do
    %OCSF.User{
      uid: get(u, :uid),
      name: get(u, :name),
      email_addr: get(u, :email_addr),
      org: parse_if(get(u, :org), &parse_org/1),
      type_id: get(u, :type_id)
    }
  end

  defp parse_org(o) do
    %OCSF.Organization{uid: get(o, :uid), name: get(o, :name)}
  end

  defp parse_entity(e) do
    %OCSF.Entity{
      name: get(e, :name),
      type: get(e, :type),
      type_id: get(e, :type_id),
      uid: get(e, :uid),
      email: get(e, :email)
    }
  end

  defp parse_iam_role(r) do
    %OCSF.IamRole{
      name: get(r, :name),
      uid: get(r, :uid),
      account: get(r, :account),
      uid_alt: get(r, :uid_alt),
      policies: get(r, :policies),
      privileges: get(r, :privileges),
      resources: get(r, :resources),
      programmatic_credentials: get(r, :programmatic_credentials),
      session: get(r, :session)
    }
  end

  defp parse_group(g) do
    %OCSF.Group{
      name: get(g, :name),
      uid: get(g, :uid),
      type: get(g, :type),
      desc: get(g, :desc)
    }
  end

  defp parse_api(a) do
    %OCSF.Api{
      operation: get(a, :operation),
      version: get(a, :version),
      service: parse_if(get(a, :service), &parse_service/1)
    }
  end

  defp parse_actor(a) do
    %OCSF.Actor{
      user: parse_if(get(a, :user), &parse_user/1),
      session: get(a, :session)
    }
  end

  defp parse_http_request(r) do
    %OCSF.HttpRequest{
      url: get(r, :url),
      user_agent: get(r, :user_agent),
      http_method: get(r, :http_method)
    }
  end

  defp parse_endpoint(e) do
    %OCSF.NetworkEndpoint{
      ip: parse_ip(get(e, :ip)),
      port: get(e, :port),
      hostname: get(e, :hostname)
    }
  end

  defp parse_service(s) do
    %OCSF.Service{
      name: get(s, :name),
      uid: get(s, :uid),
      version: get(s, :version)
    }
  end

  defp parse_ip(nil), do: nil

  defp parse_ip(ip) when is_binary(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, addr} -> addr
      _ -> ip
    end
  end

  defp parse_ip(ip) when is_tuple(ip), do: ip

  defp parse_time(nil), do: nil
  defp parse_time(%DateTime{} = dt), do: dt

  defp parse_time(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_if(nil, _fun), do: nil
  defp parse_if(val, fun), do: fun.(val)

  defp parse_list_if(nil, _fun), do: nil
  defp parse_list_if(list, fun) when is_list(list), do: Enum.map(list, fun)

  defp get(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
