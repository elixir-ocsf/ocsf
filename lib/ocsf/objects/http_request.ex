defmodule OCSF.HttpRequest do
  @moduledoc """
  OCSF HTTP Request object.

  Represents an HTTP request associated with an OCSF event. Used to
  capture request-level context such as the URL, user agent, and HTTP
  method.

  Corresponds to the OCSF
  [HTTP Request](https://schema.ocsf.io/1.8.0/objects/http_request) object.

  ## Fields

  - `:url` -- request URL. Classified as `:network`.
  - `:user_agent` -- user agent string. Classified as `:network`.
  - `:http_method` -- HTTP method (e.g. `"GET"`, `"POST"`). Classified as `:taxonomic`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.NetworkEndpoint` for network endpoint information.
  """

  @type t :: %__MODULE__{
          url: String.t() | nil,
          user_agent: String.t() | nil,
          http_method: String.t() | nil
        }

  defstruct [:url, :user_agent, :http_method]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      url: [class: :network, erasable: false],
      user_agent: [class: :network, erasable: false],
      http_method: [class: :taxonomic, erasable: false]
    ]
  end
end
