defmodule OCSF.NetworkEndpoint do
  @moduledoc """
  OCSF Network Endpoint object (`src_endpoint` / `dst_endpoint`).

  Represents a network endpoint involved in an OCSF event, used as
  either the source or destination endpoint.

  Corresponds to the OCSF
  [Network Endpoint](https://schema.ocsf.io/1.8.0/objects/network_endpoint) object.

  ## Fields

  - `:ip` -- IP address (`:inet.ip_address()` tuple). Classified as `:network`.
  - `:port` -- TCP/UDP port number. Classified as `:network`.
  - `:hostname` -- DNS hostname. Classified as `:network`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.HttpRequest` for HTTP-level request details.
  """

  @type t :: %__MODULE__{
          ip: :inet.ip_address() | nil,
          port: integer | nil,
          hostname: String.t() | nil
        }

  defstruct [:ip, :port, :hostname]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      ip: [class: :network, erasable: false],
      port: [class: :network, erasable: false],
      hostname: [class: :network, erasable: false]
    ]
  end
end
