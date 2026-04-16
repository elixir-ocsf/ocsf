defmodule OCSF.UUID do
  @moduledoc """
  UUIDv7 helpers.

  Delegates to the `uuid_v7` library which provides a compliant
  implementation with an 18-bit randomly-seeded counter for
  sub-millisecond ordering. Used to generate unique identifiers for
  OCSF event metadata.

  See `OCSF.Metadata` for how generated UUIDs are used.
  """

  @doc """
  Generate a UUIDv7 as a 16-byte raw binary.

  ## Examples

      iex> raw = OCSF.UUID.v7()
      iex> byte_size(raw)
      16
  """
  @spec v7() :: <<_::128>>
  def v7, do: UUIDv7.bingenerate()

  @doc """
  Generate a UUIDv7 as a lowercase hex string with dashes.

  ## Examples

      iex> uuid = OCSF.UUID.v7_string()
      iex> String.match?(uuid, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
      true
  """
  @spec v7_string() :: String.t()
  def v7_string, do: UUIDv7.generate()
end
