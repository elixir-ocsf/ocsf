defmodule OCSF.EventCodeFormat do
  @moduledoc """
  Format-driven `metadata.event_code` generation.

  Derives a human-readable event code from existing OCSF field values.
  No parallel taxonomy is introduced — `event_code` is a convenience
  projection for SIEM search, log grep, and dashboards.

  ## Example

      format = OCSF.EventCodeFormat.get(:default)
      OCSF.EventCodeFormat.generate(format, event)
      #=> "authentication:magic_link:logon"

  See `EVENT_CODE_FORMAT_CONFIG_SPEC.md` for the full specification.

  See `OCSF.Events.Authentication` for how builders integrate with
  event code generation.
  """

  @type t :: %__MODULE__{
          fields: [[atom]],
          separator: String.t()
        }

  defstruct fields: [], separator: ":"

  @virtual_path_keys [
    [:class_name],
    [:activity_name],
    [:category_name],
    [:severity],
    [:status]
  ]

  @doc """
  Retrieve a named format from application config.

  Reads from `config :ocsf, event_code: [formats: %{name => opts}]`.
  Returns `nil` if the format is not configured.

  ## Examples

      iex> OCSF.EventCodeFormat.get(:nonexistent)
      nil
  """
  @spec get(atom) :: t | nil
  def get(name) when is_atom(name) do
    config = Application.get_env(:ocsf, :event_code, [])
    formats = Keyword.get(config, :formats, %{})

    case Map.get(formats, name) do
      nil -> nil
      opts -> struct(__MODULE__, opts)
    end
  end

  @doc """
  Return the configured default format name, or `nil`.
  """
  @spec default_format() :: atom | nil
  def default_format do
    config = Application.get_env(:ocsf, :event_code, [])
    Keyword.get(config, :default_format)
  end

  @doc """
  Generate an event code from a format and an event.

  Returns `nil` if all field paths resolve to nil/empty.

  ## Examples

      iex> format = %OCSF.EventCodeFormat{
      ...>   fields: [[:class_name], [:activity_name]],
      ...>   separator: ":"
      ...> }
      iex> event = %OCSF.Event{class_uid: 3002, activity_id: 1,
      ...>   category_uid: 3, type_uid: 300201, severity_id: 1, status_id: 1,
      ...>   time: ~U[2026-04-15 10:00:00Z],
      ...>   metadata: %OCSF.Metadata{uid: "x", version: "1.9.0",
      ...>     product: %OCSF.Product{name: "T"}},
      ...>   user: %OCSF.User{uid: "u"}}
      iex> OCSF.EventCodeFormat.generate(format, event)
      "authentication:logon"
  """
  @spec generate(t, OCSF.Event.t()) :: String.t() | nil
  def generate(%__MODULE__{} = format, %OCSF.Event{} = event) do
    parts =
      format.fields
      |> Stream.map(&resolve_field(&1, event))
      |> Stream.reject(&is_nil/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(&normalize/1)
      |> Enum.reject(&(&1 == ""))

    case parts do
      [] -> nil
      parts -> Enum.join(parts, format.separator)
    end
  end

  defp resolve_field(path, event) do
    if path in @virtual_path_keys do
      resolve_virtual(path, event)
    else
      resolve_physical(path, event)
    end
  end

  defp resolve_virtual([:class_name], event), do: resolve_class_name(event)
  defp resolve_virtual([:activity_name], event), do: resolve_activity_name(event)
  defp resolve_virtual([:category_name], event), do: resolve_category_name(event)
  defp resolve_virtual([:severity], event), do: resolve_severity(event)
  defp resolve_virtual([:status], event), do: resolve_status(event)

  defp resolve_physical(path, struct) do
    Enum.reduce_while(path, struct, fn key, acc ->
      case acc do
        %{} -> {:cont, Map.get(acc, key)}
        _ -> {:halt, nil}
      end
    end)
  end

  defp resolve_class_name(%{class_uid: uid}) do
    case OCSF.Class.name(uid) do
      nil -> nil
      name -> Atom.to_string(name)
    end
  end

  defp resolve_activity_name(%{class_uid: class_uid, activity_id: activity_id}) do
    case OCSF.Activity.label(class_uid, activity_id) do
      nil -> nil
      name -> Atom.to_string(name)
    end
  end

  defp resolve_category_name(%{category_uid: uid}) do
    case OCSF.Category.name(uid) do
      nil -> nil
      name -> Atom.to_string(name)
    end
  end

  defp resolve_severity(%{severity_id: uid}) do
    case OCSF.Severity.name(uid) do
      nil -> nil
      name -> Atom.to_string(name)
    end
  end

  defp resolve_status(%{status_id: uid}) do
    case OCSF.Status.name(uid) do
      nil -> nil
      name -> Atom.to_string(name)
    end
  end

  @doc """
  Normalize a string value for use in an event code.

  Trims whitespace, lowercases, replaces non-alphanumeric characters
  with `_`, collapses consecutive `_`, and strips leading/trailing `_`.

  ## Examples

      iex> OCSF.EventCodeFormat.normalize("Authentication")
      "authentication"

      iex> OCSF.EventCodeFormat.normalize("Magic Link")
      "magic_link"

      iex> OCSF.EventCodeFormat.normalize("User-Login!")
      "user_login"
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "_")
    |> String.replace(~r/_{2,}/, "_")
    |> String.trim("_")
  end

  def normalize(value) when is_atom(value), do: value |> Atom.to_string() |> normalize()
  def normalize(value), do: value |> to_string() |> normalize()
end
