defmodule OCSF.Product do
  @moduledoc """
  OCSF Product object (nested in Metadata).

  Describes the product that generated or reported an OCSF event.
  Nested inside `OCSF.Metadata` as the `:product` field.

  Corresponds to the OCSF
  [Product](https://schema.ocsf.io/1.8.0/objects/product) object.

  ## Fields

  - `:name` -- product name. Classified as `:taxonomic`.
  - `:vendor_name` -- vendor or publisher name. Classified as `:taxonomic`.
  - `:feature` -- `%OCSF.Feature{}` or `nil`. Classified as `:taxonomic`.
  - `:uid` -- unique product identifier. Classified as `:identifier`.
  - `:version` -- product version string. Classified as `:taxonomic`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Feature` and `OCSF.Metadata` for related modules.
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          vendor_name: String.t() | nil,
          feature: OCSF.Feature.t() | nil,
          uid: String.t() | nil,
          version: String.t() | nil
        }

  defstruct [:name, :vendor_name, :feature, :uid, :version]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :taxonomic, erasable: false],
      vendor_name: [class: :taxonomic, erasable: false],
      feature: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      version: [class: :taxonomic, erasable: false]
    ]
  end
end
