defmodule OCSF.Actor do
  @moduledoc """
  OCSF Actor object.

  Represents the entity (user and/or session) that initiated the action
  described by an OCSF event.

  Corresponds to the OCSF
  [Actor](https://schema.ocsf.io/1.8.0/objects/actor) object.

  ## Fields

  - `:user` -- `%OCSF.User{}` or `nil`. Classified as `:identity`.
  - `:session` -- session map or `nil`. Classified as `:identifier`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.

  See `OCSF.User` for the nested user object.
  """

  @type t :: %__MODULE__{
          user: OCSF.User.t() | nil,
          session: map | nil
        }

  defstruct [:user, :session]

  @doc "Return field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [
      user: [class: :identity, erasable: false],
      session: [class: :identifier, erasable: false]
    ]
  end
end
