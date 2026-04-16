defmodule OCSFTest do
  use ExUnit.Case, async: true

  test "version/0 returns OCSF 1.8.0" do
    assert OCSF.version() == "1.8.0"
  end
end
