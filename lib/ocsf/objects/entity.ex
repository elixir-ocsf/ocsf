defmodule OCSF.Entity do
  @moduledoc """
  OCSF Managed Entity object.

  Represents the entity managed in an Entity Management event (class
  3004) -- the user, group, policy, or other object being created,
  updated, or removed.

  Corresponds to the OCSF
  [Managed Entity](https://schema.ocsf.io/1.8.0/objects/managed_entity)
  object. Carried in `OCSF.Event`'s `:entity` field, which is required
  for the Entity Management class.

  ## Fields

  - `:name` -- entity display name. Classified as `:identity`.
  - `:type` -- entity type label (e.g. `"User"`, `"Group"`).
    Classified as `:taxonomic`.
  - `:type_id` -- numeric entity type. Classified as `:taxonomic`.
  - `:uid` -- unique entity identifier. Classified as `:identifier`.
  - `:email` -- entity email address, when applicable. Classified as
    `:contact`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Events.EntityManagement` for the builder that emits events
  carrying this object.
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          type: String.t() | nil,
          type_id: integer | nil,
          uid: String.t() | nil,
          email: String.t() | nil
        }

  defstruct [:name, :type, :type_id, :uid, :email]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :identity, erasable: true],
      type: [class: :taxonomic, erasable: false],
      type_id: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      email: [class: :contact, erasable: true]
    ]
  end
end
