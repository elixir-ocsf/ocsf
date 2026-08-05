defmodule OCSF.Metadata do
  @moduledoc """
  OCSF Metadata object.

  Carries event-level metadata such as the schema version, correlation
  identifiers, and product information. Every OCSF event embeds one
  `%OCSF.Metadata{}` struct.

  Corresponds to the OCSF
  [Metadata](https://schema.ocsf.io/1.9.0/objects/metadata) object.

  ## Fields

  - `:uid` -- unique event identifier. Classified as `:identifier`.
  - `:version` -- OCSF schema version (e.g. `"1.9.0"`). Classified as `:taxonomic`.
  - `:product` -- `%OCSF.Product{}` describing the reporting product. Classified as `:taxonomic`.
  - `:profiles` -- list of OCSF profile strings applied to the event. Classified as `:taxonomic`.
  - `:event_code` -- optional application-specific event code. Classified as `:taxonomic`.
  - `:correlation_uid` -- optional correlation identifier linking related events. Classified as `:identifier`.
  - `:trace_uid` -- optional distributed-trace identifier. Classified as `:identifier`.
  - `:span_uid` -- optional span identifier within a trace. Classified as `:identifier`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.Product`, `OCSF.Correlation`, and `OCSF.UUID` for related modules.
  """

  @type t :: %__MODULE__{
          uid: String.t(),
          version: String.t(),
          product: OCSF.Product.t(),
          profiles: [String.t()],
          event_code: String.t() | nil,
          correlation_uid: String.t() | nil,
          trace_uid: String.t() | nil,
          span_uid: String.t() | nil
        }

  defstruct [
    :uid,
    :version,
    :product,
    profiles: [],
    event_code: nil,
    correlation_uid: nil,
    trace_uid: nil,
    span_uid: nil
  ]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      uid: [class: :identifier, erasable: false],
      version: [class: :taxonomic, erasable: false],
      product: [class: :taxonomic, erasable: false],
      profiles: [class: :taxonomic, erasable: false],
      event_code: [class: :taxonomic, erasable: false],
      correlation_uid: [class: :identifier, erasable: false],
      trace_uid: [class: :identifier, erasable: false],
      span_uid: [class: :identifier, erasable: false]
    ]
  end
end
