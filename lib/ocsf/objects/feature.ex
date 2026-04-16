defmodule OCSF.Feature do
  @moduledoc """
  OCSF Feature object (nested in Product).

  Describes a specific feature or component within a product that
  generated an OCSF event. Nested inside `OCSF.Product` as the
  `:feature` field.

  Corresponds to the OCSF
  [Feature](https://schema.ocsf.io/1.8.0/objects/feature) object.

  ## Fields

  - `:name` -- feature name. Classified as `:taxonomic`.
  - `:uid` -- unique feature identifier. Classified as `:identifier`.
  - `:version` -- feature version string. Classified as `:taxonomic`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Product` for the parent object that embeds features.
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          uid: String.t() | nil,
          version: String.t() | nil
        }

  defstruct [:name, :uid, :version]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      version: [class: :taxonomic, erasable: false]
    ]
  end
end
