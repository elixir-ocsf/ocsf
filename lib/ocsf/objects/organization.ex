defmodule OCSF.Organization do
  @moduledoc """
  OCSF Organization object.

  Represents a tenant or organizational entity in an OCSF event.
  Typically nested inside `OCSF.User` to identify the user's
  organization.

  Corresponds to the OCSF
  [Organization](https://schema.ocsf.io/1.8.0/objects/organization) object.

  ## Fields

  - `:uid` -- unique organization identifier. Classified as `:tenant`.
  - `:name` -- organization display name. Classified as `:identity`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.User` for the parent object that embeds organizations.
  """

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          name: String.t() | nil
        }

  defstruct [:uid, :name]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      uid: [class: :tenant, erasable: false],
      name: [class: :identity, erasable: false]
    ]
  end
end
