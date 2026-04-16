defmodule OCSF.Feature do
  @moduledoc "OCSF Feature object (nested in Product)."

  @type t :: %__MODULE__{
          name: String.t() | nil,
          uid: String.t() | nil,
          version: String.t() | nil
        }

  defstruct [:name, :uid, :version]

  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      name: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      version: [class: :taxonomic, erasable: false]
    ]
  end
end
