defmodule OCSF.NetworkEndpoint do
  @moduledoc "OCSF Network Endpoint object (src_endpoint / dst_endpoint)."

  @type t :: %__MODULE__{
          ip: :inet.ip_address() | nil,
          port: integer | nil,
          hostname: String.t() | nil
        }

  defstruct [:ip, :port, :hostname]

  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      ip: [class: :network, erasable: false],
      port: [class: :network, erasable: false],
      hostname: [class: :network, erasable: false]
    ]
  end
end
