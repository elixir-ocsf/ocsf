defmodule OCSF.Service do
  @moduledoc """
  OCSF Service object.

  Represents a service or application involved in an OCSF event, such
  as the service being authenticated against or the API being called.

  Corresponds to the OCSF
  [Service](https://schema.ocsf.io/1.9.0/objects/service) object.

  ## Fields

  - `:name` -- service name. Classified as `:taxonomic`.
  - `:uid` -- unique service identifier. Classified as `:identifier`.
  - `:version` -- service version string. Classified as `:taxonomic`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Product` and `OCSF.Feature` for product-level identification.
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
