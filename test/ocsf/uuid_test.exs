defmodule OCSF.UUIDTest do
  use ExUnit.Case, async: true

  alias OCSF.UUID

  describe "v7/0" do
    test "returns a 16-byte binary" do
      uuid = UUID.v7()
      assert byte_size(uuid) == 16
    end

    test "has version 7 and variant 10" do
      <<_::48, version::4, _::12, variant::2, _::62>> = UUID.v7()
      assert version == 0b0111
      assert variant == 0b10
    end

    test "is time-sortable across milliseconds" do
      uuid1 = UUID.v7()
      Process.sleep(2)
      uuid2 = UUID.v7()

      # Different millisecond timestamps -> uuid1 < uuid2
      <<ts1::48, _::80>> = uuid1
      <<ts2::48, _::80>> = uuid2
      assert ts2 >= ts1
      assert uuid1 < uuid2
    end
  end

  describe "v7_string/0" do
    test "returns a valid UUID string" do
      uuid = UUID.v7_string()
      assert String.length(uuid) == 36

      assert Regex.match?(
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
               uuid
             )
    end

    test "produces unique values" do
      uuids = for _ <- 1..1000, do: UUID.v7_string()
      assert length(Enum.uniq(uuids)) == 1000
    end
  end
end
