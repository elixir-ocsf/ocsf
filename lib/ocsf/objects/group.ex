defmodule OCSF.Group do
  @moduledoc """
  OCSF Group object.

  Represents a group, role, or organizational unit -- the subject of a
  Group Management event (class 3006) and a common membership container
  elsewhere in OCSF.

  Corresponds to the OCSF
  [Group](https://schema.ocsf.io/1.9.0/objects/group) object. Carried in
  `OCSF.Event`'s `:group` field, which is required for the Group
  Management class.

  ## Fields

  - `:name` -- group name. Classified as `:taxonomic`.
  - `:uid` -- unique group identifier. Classified as `:identifier`.
  - `:type` -- group type label. Classified as `:taxonomic`.
  - `:desc` -- group description. Classified as `:taxonomic`.

  ## PII classification

  Groups are not personal data; all fields are non-erasable. See
  `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Events.GroupManagement` for the builder that emits events
  carrying this object.
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          uid: String.t() | nil,
          type: String.t() | nil,
          desc: String.t() | nil
        }

  defstruct [:name, :uid, :type, :desc]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      type: [class: :taxonomic, erasable: false],
      desc: [class: :taxonomic, erasable: false]
    ]
  end
end
