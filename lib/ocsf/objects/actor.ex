defmodule OCSF.Actor do
  @moduledoc "OCSF Actor object."

  @type t :: %__MODULE__{
          user: OCSF.User.t() | nil,
          session: map | nil
        }

  defstruct [:user, :session]

  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      user: [class: :identity, erasable: false],
      session: [class: :identifier, erasable: false]
    ]
  end
end
