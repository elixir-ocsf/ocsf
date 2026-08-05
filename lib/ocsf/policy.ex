defmodule OCSF.Policy do
  @moduledoc """
  Sink redaction policy.

  Defines which data classes a **sink** allows, denies, or transforms
  before writing. Every sink declares a policy; `apply/2` enforces it
  on an event by walking nested objects and dropping or transforming
  fields based on their `__ocsf_fields__/0` classification.

  `:credential` is always denied — not configurable.

  ## Example

      policy = %OCSF.Policy{
        allow: [:identifier, :tenant, :taxonomic, :temporal],
        deny:  [:contact, :identity, :network],
        transform: []
      }

      redacted = OCSF.Policy.apply(policy, event)
      # redacted event has no PII fields

  See `OCSF.Classification`, `OCSF.Sink`.
  """

  @type transform ::
          :truncate_v4_24
          | :truncate_v6_48
          | :hash_salted
          | :ua_parse_only
          | :drop
          | {module, atom, list}

  @type t :: %__MODULE__{
          allow: [OCSF.Classification.data_class()],
          deny: [OCSF.Classification.data_class()],
          transform: keyword
        }

  defstruct allow: [], deny: [], transform: []

  @doc """
  Apply a policy to an event, returning a redacted event.

  Walks all nested objects and drops fields whose data class is denied.
  `:credential` is always dropped regardless of policy. `deny` always
  wins over `allow`.
  """
  @spec apply(t, OCSF.Event.t()) :: OCSF.Event.t()
  def apply(%__MODULE__{} = policy, %OCSF.Event{} = event) do
    %{
      event
      | user: redact_struct(policy, event.user),
        updated_user: redact_struct(policy, event.updated_user),
        entity: redact_struct(policy, event.entity),
        group: redact_struct(policy, event.group),
        groups: redact_list(policy, event.groups),
        iam_role: redact_struct(policy, event.iam_role),
        iam_roles: redact_list(policy, event.iam_roles),
        updated_role: redact_struct(policy, event.updated_role),
        api: redact_struct(policy, event.api),
        actor: redact_actor(policy, event.actor),
        http_request: redact_struct(policy, event.http_request),
        src_endpoint: redact_struct(policy, event.src_endpoint),
        dst_endpoint: redact_struct(policy, event.dst_endpoint),
        service: redact_struct(policy, event.service)
    }
  end

  defp redact_list(_policy, nil), do: nil

  defp redact_list(policy, structs) when is_list(structs),
    do: Enum.map(structs, &redact_struct(policy, &1))

  defp redact_actor(_policy, nil), do: nil

  defp redact_actor(policy, %OCSF.Actor{} = actor) do
    %{actor | user: redact_struct(policy, actor.user)}
  end

  defp redact_struct(_policy, nil), do: nil

  defp redact_struct(policy, %{__struct__: mod} = struct) do
    fields = mod.__ocsf_fields__()

    Enum.reduce(fields, struct, fn {field_name, opts}, acc ->
      if should_nil_field?(policy, opts[:class]) do
        Map.put(acc, field_name, nil)
      else
        acc
      end
    end)
  end

  defp should_nil_field?(_policy, :credential), do: true

  defp should_nil_field?(policy, class) when is_atom(class) do
    cond do
      class in policy.deny -> true
      class in policy.allow -> false
      true -> OCSF.Classification.default_policy(class) == :deny
    end
  end
end
