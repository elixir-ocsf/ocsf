defmodule OCSF.IamRole do
  @moduledoc """
  OCSF IAM Role object.

  Represents a role -- a named bundle of privileges, policies, and
  resource grants -- that is the subject of a Role Management event
  (class 3008) and an assignable grant in a User Management event
  (class 3007).

  Corresponds to the OCSF
  [IAM Role](https://schema.ocsf.io/1.9.0/objects/iam_role) object.
  Carried in `OCSF.Event`'s `:iam_role`/`:iam_roles` fields.

  ## Fields

  - `:name` -- role name. Classified as `:identifier`. Observable id `49`.
  - `:uid` -- unique role identifier. Classified as `:identifier`.
    Observable id `50`.
  - `:account` -- owning account/tenant identifier. Classified as
    `:tenant`.
  - `:uid_alt` -- alternate role identifier (e.g. ARN). Classified as
    `:identifier`.
  - `:policies` -- list of attached policy identifiers. Classified as
    `:taxonomic`.
  - `:privileges` -- list of privilege strings granted by the role.
    Classified as `:taxonomic`.
  - `:resources` -- list of resource identifiers the role grants access
    to. Classified as `:taxonomic`.
  - `:programmatic_credentials` -- list of programmatic credentials
    (access keys, tokens) bound to the role. Classified as `:credential`
    and always redacted.
  - `:session` -- session context map, when the role is materialised into
    an assumed session. Classified as `:identifier`.

  ## Observables

  OCSF marks `name` and `uid` as observables (ids `49` and `50`). The
  ids are recorded alongside each field in `__ocsf_fields__/0`.

  ## PII classification

  Roles are not personal data; all fields are non-erasable. See
  `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Events.RoleManagement` and `OCSF.Events.UserManagement` for
  the builders that emit events carrying this object.
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          uid: String.t() | nil,
          account: String.t() | nil,
          uid_alt: String.t() | nil,
          policies: [term] | nil,
          privileges: [term] | nil,
          resources: [term] | nil,
          programmatic_credentials: [term] | nil,
          session: map | nil
        }

  defstruct [
    :name,
    :uid,
    :account,
    :uid_alt,
    :policies,
    :privileges,
    :resources,
    :programmatic_credentials,
    :session
  ]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :identifier, erasable: false, observable: 49],
      uid: [class: :identifier, erasable: false, observable: 50],
      account: [class: :tenant, erasable: false],
      uid_alt: [class: :identifier, erasable: false],
      policies: [class: :taxonomic, erasable: false],
      privileges: [class: :taxonomic, erasable: false],
      resources: [class: :taxonomic, erasable: false],
      programmatic_credentials: [class: :credential, erasable: false],
      session: [class: :identifier, erasable: false]
    ]
  end
end
