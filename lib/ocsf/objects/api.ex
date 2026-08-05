defmodule OCSF.Api do
  @moduledoc """
  OCSF API object.

  Describes a management-plane or programmatic API call -- the subject
  of an API Activity event (class 6003). Captures the invoked
  `operation` and the `service` that exposes it.

  Corresponds to the OCSF
  [API](https://schema.ocsf.io/1.8.0/objects/api) object. Carried in
  `OCSF.Event`'s `:api` field, which is required for the API Activity
  class.

  ## Fields

  - `:operation` -- the API operation invoked (e.g. `"CreateUser"`).
    Required by OCSF. Classified as `:taxonomic`.
  - `:version` -- the API version string. Classified as `:taxonomic`.
  - `:service` -- the `OCSF.Service` exposing the operation.

  ## PII classification

  API metadata is not personal data; all scalar fields are
  non-erasable. See `OCSF.Classification` for data class definitions.
  Call `__ocsf_fields__/0` to inspect this module's field
  classifications.

  See `OCSF.Events.ApiActivity` for the builder that emits events
  carrying this object.
  """

  @type t :: %__MODULE__{
          operation: String.t() | nil,
          version: String.t() | nil,
          service: OCSF.Service.t() | nil
        }

  defstruct [:operation, :version, :service]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      operation: [class: :taxonomic, erasable: false],
      version: [class: :taxonomic, erasable: false]
    ]
  end
end
