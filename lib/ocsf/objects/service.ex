defmodule OCSF.Service do
  @moduledoc "OCSF Service object."

  @type t :: %__MODULE__{
          name: String.t() | nil,
          uid: String.t() | nil,
          version: String.t() | nil
        }

  defstruct [:name, :uid, :version]

  def __ocsf_fields__ do
    [
      name: [class: :taxonomic, erasable: false],
      uid: [class: :identifier, erasable: false],
      version: [class: :taxonomic, erasable: false]
    ]
  end
end
