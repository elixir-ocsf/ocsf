defmodule OCSF.HttpRequest do
  @moduledoc "OCSF HTTP Request object."

  @type t :: %__MODULE__{
          url: String.t() | nil,
          user_agent: String.t() | nil,
          http_method: String.t() | nil
        }

  defstruct [:url, :user_agent, :http_method]

  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      url: [class: :network, erasable: false],
      user_agent: [class: :network, erasable: false],
      http_method: [class: :taxonomic, erasable: false]
    ]
  end
end
