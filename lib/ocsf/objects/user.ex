defmodule OCSF.User do
  @moduledoc "OCSF User object."

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          name: String.t() | nil,
          email_addr: String.t() | nil,
          org: OCSF.Organization.t() | nil,
          type_id: integer | nil
        }

  defstruct [:uid, :name, :email_addr, :org, :type_id]

  def __ocsf_fields__ do
    [
      uid: [class: :identifier, erasable: false],
      name: [class: :identity, erasable: true],
      email_addr: [class: :contact, erasable: true],
      org: [class: :tenant, erasable: false],
      type_id: [class: :taxonomic, erasable: false]
    ]
  end
end
