defmodule OCSF.User do
  @moduledoc """
  OCSF User object.

  Represents a user identity in an OCSF event. Corresponds to the
  OCSF [User](https://schema.ocsf.io/1.9.0/objects/user) object.

  ## Fields

  - `:uid` -- unique user identifier. Classified as `:identifier`.
  - `:name` -- display name. Classified as `:identity` (PII, erasable).
  - `:email_addr` -- email address. Classified as `:contact` (PII, erasable).
  - `:org` -- `%OCSF.Organization{}` or `nil`. Classified as `:tenant`.
  - `:type_id` -- user type identifier. Classified as `:taxonomic`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Organization`, `OCSF.Actor`, and `OCSF.Classification` for
  related modules.
  """

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          name: String.t() | nil,
          email_addr: String.t() | nil,
          org: OCSF.Organization.t() | nil,
          type_id: integer | nil
        }

  defstruct [:uid, :name, :email_addr, :org, :type_id]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      uid: [class: :identifier, erasable: false],
      name: [class: :identity, erasable: true],
      email_addr: [class: :contact, erasable: true],
      org: [class: :tenant, erasable: false],
      type_id: [class: :taxonomic, erasable: false]
    ]
  end
end
