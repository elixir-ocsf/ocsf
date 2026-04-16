defmodule OCSF.UUID do
  @moduledoc """
  UUIDv7 helpers.

  Delegates to the `uuid_v7` library which provides a compliant
  implementation with an 18-bit randomly-seeded counter for
  sub-millisecond ordering.
  """

  @doc "Generates a UUIDv7 as a 16-byte raw binary."
  @spec v7() :: <<_::128>>
  def v7, do: UUIDv7.bingenerate()

  @doc "Generates a UUIDv7 as a lowercase hex string with dashes."
  @spec v7_string() :: String.t()
  def v7_string, do: UUIDv7.generate()
end
