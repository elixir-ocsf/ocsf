defmodule OCSF.Metadata do
  @moduledoc "OCSF Metadata object."

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
