defmodule OCSF.Product do
  @moduledoc "OCSF Product object (nested in Metadata)."

  @type t :: %__MODULE__{
          name: String.t() | nil,
          vendor_name: String.t() | nil,
          feature: OCSF.Feature.t() | nil,
          uid: String.t() | nil,
          version: String.t() | nil
        }

  defstruct [:name, :vendor_name, :feature, :uid, :version]

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
