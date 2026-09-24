defmodule OCSF.ResourceDetails do
  @moduledoc """
  OCSF Resource Details object.

  Describes a resource affected by, or granted through, an IAM or API
  activity: a bucket, a table, a queue, a secret. Carried as a list in
  `OCSF.Event`'s `:resources` field on Group Management (3006), User
  Management (3007), Role Management (3008) and API Activity (6003)
  events, and in `OCSF.IamRole`'s `:resources` field.

  Corresponds to the OCSF
  [Resource Details](https://schema.ocsf.io/1.9.0/objects/resource_details)
  object. OCSF requires at least one of `name` or `uid` per resource.
  Only the subset of attributes the library models is listed below;
  the remaining OCSF attributes can be carried in `unmapped`.

  ## Fields

  - `:name` -- resource name. Classified as `:taxonomic`.
  - `:uid` -- unique resource identifier (e.g. an ARN). Classified as
    `:identifier`.
  - `:uid_alt` -- alternate identifier. Classified as `:identifier`.
  - `:type` -- resource type label. Classified as `:taxonomic`.
  - `:labels` -- list of free-form labels. Classified as `:taxonomic`.
  - `:namespace` -- namespace the resource lives in. Classified as
    `:taxonomic`.
  - `:region` -- cloud region. Classified as `:taxonomic`.
  - `:version` -- resource version. Classified as `:taxonomic`.
  - `:owner` -- `%OCSF.User{}` or `nil`, the resource owner. Classified
    as `:identity`; the nested user is redacted by its own
    classification.
  - `:group` -- `%OCSF.Group{}` or `nil`, the owning group. Classified
    as `:taxonomic`.
  - `:data` -- free-form map of additional resource data. Classified as
    `:taxonomic`.

  ## PII classification

  Resources are not personal data, except for the nested `owner` user.
  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Events.RoleManagement`, `OCSF.Events.UserManagement`,
  `OCSF.Events.GroupManagement` and `OCSF.Events.ApiActivity` for the
  builders that emit events carrying this object.
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          uid: String.t() | nil,
          uid_alt: String.t() | nil,
          type: String.t() | nil,
          labels: [String.t()] | nil,
          namespace: String.t() | nil,
          region: String.t() | nil,
          version: String.t() | nil,
          owner: OCSF.User.t() | nil,
          group: OCSF.Group.t() | nil,
          data: map | nil
        }

  defstruct [
    :name,
    :uid,
    :uid_alt,
    :type,
    :labels,
    :namespace,
    :region,
    :version,
    :owner,
    :group,
    :data
  ]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      uid_alt: [class: :identifier, erasable: false],
      type: [class: :taxonomic, erasable: false],
      labels: [class: :taxonomic, erasable: false],
      namespace: [class: :taxonomic, erasable: false],
      region: [class: :taxonomic, erasable: false],
      version: [class: :taxonomic, erasable: false],
      owner: [class: :identity, erasable: false],
      group: [class: :taxonomic, erasable: false],
      data: [class: :taxonomic, erasable: false]
    ]
  end
end
