defmodule OCSF.Organization do
  @moduledoc "OCSF Organization object."

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          name: String.t() | nil
        }

  defstruct [:uid, :name]

  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      uid: [class: :tenant, erasable: false],
      name: [class: :identity, erasable: false]
    ]
  end
end
