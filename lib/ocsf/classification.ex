defmodule OCSF.Classification do
  @moduledoc """
  Data class taxonomy for PII classification.

  Every field in an OCSF nested object struct is tagged with a data class
  via `__ocsf_fields__/0`. Sink policies use these classes to decide
  which fields to allow, deny, or transform.
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

  @doc "Returns all valid data classes."
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

  @doc "Returns true if the class is classified as PII by default."
  @spec pii?(data_class) :: boolean
  def pii?(:contact), do: true
  def pii?(:identity), do: true
  def pii?(:credential), do: true
  def pii?(_), do: false

  @doc "Returns the default sink policy for a data class."
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
