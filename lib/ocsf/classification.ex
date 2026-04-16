defmodule OCSF.Classification do
  @moduledoc """
  Data class taxonomy for PII classification.

  Every field in an OCSF nested object struct is tagged with a **data class**
  via `__ocsf_fields__/0`. Sink **policies** use these classes to decide
  which fields to allow, deny, or transform during **redaction**.

  ## Data classes

  | Class          | PII? | Default policy |
  |----------------|------|----------------|
  | `:identifier`  | No   | `:allow`       |
  | `:tenant`      | No   | `:allow`       |
  | `:taxonomic`   | No   | `:allow`       |
  | `:temporal`    | No   | `:allow`       |
  | `:contact`     | Yes  | `:deny`        |
  | `:identity`    | Yes  | `:deny`        |
  | `:network`     | No   | `:deny`        |
  | `:geolocation` | No   | `:deny`        |
  | `:credential`  | Yes  | `:deny`        |

  See `OCSF.User`, `OCSF.Organization`, and other struct modules for
  per-field classification via `__ocsf_fields__/0`.
  """

  @type data_class ::
          :identifier
          | :tenant
          | :taxonomic
          | :temporal
          | :contact
          | :identity
          | :network
          | :geolocation
          | :credential

  @doc """
  Return all valid data classes.

  ## Examples

      iex> OCSF.Classification.data_classes()
      [:identifier, :tenant, :taxonomic, :temporal, :contact, :identity, :network, :geolocation, :credential]
  """
  @spec data_classes() :: [data_class]
  def data_classes do
    [
      :identifier,
      :tenant,
      :taxonomic,
      :temporal,
      :contact,
      :identity,
      :network,
      :geolocation,
      :credential
    ]
  end

  @doc """
  Return true if the class is classified as PII by default.

  The PII classes are `:contact`, `:identity`, and `:credential`.

  ## Examples

      iex> OCSF.Classification.pii?(:contact)
      true

      iex> OCSF.Classification.pii?(:identity)
      true

      iex> OCSF.Classification.pii?(:identifier)
      false
  """
  @spec pii?(data_class) :: boolean
  def pii?(:contact), do: true
  def pii?(:identity), do: true
  def pii?(:credential), do: true
  def pii?(_), do: false

  @doc """
  Return the default **sink** **policy** for a data class.

  Non-sensitive classes default to `:allow`; sensitive classes default
  to `:deny`.

  ## Examples

      iex> OCSF.Classification.default_policy(:identifier)
      :allow

      iex> OCSF.Classification.default_policy(:contact)
      :deny
  """
  @spec default_policy(data_class) :: :allow | :deny
  def default_policy(:identifier), do: :allow
  def default_policy(:tenant), do: :allow
  def default_policy(:taxonomic), do: :allow
  def default_policy(:temporal), do: :allow
  def default_policy(:contact), do: :deny
  def default_policy(:identity), do: :deny
  def default_policy(:network), do: :deny
  def default_policy(:geolocation), do: :deny
  def default_policy(:credential), do: :deny
end
