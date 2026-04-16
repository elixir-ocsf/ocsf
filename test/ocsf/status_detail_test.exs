defmodule OCSF.StatusDetailTest do
  use ExUnit.Case, async: true

  alias OCSF.StatusDetail

  describe "values/1" do
    test "returns well-known strings for Authentication (3002)" do
      values = StatusDetail.values(3002)
      assert "user_does_not_exist" in values
      assert "invalid_credentials" in values
      assert "account_disabled" in values
      assert "account_locked_out" in values
      assert "password_expired" in values
      assert "mfa_required" in values
      assert "unknown_error" in values
      assert "logoff_user_initiated" in values
      assert "logoff_other" in values
    end

    test "returns empty for unknown class" do
      assert StatusDetail.values(9999) == []
    end
  end

  describe "valid?/2" do
    test "checks known values" do
      assert StatusDetail.valid?(3002, "invalid_credentials")
      refute StatusDetail.valid?(3002, "made_up_detail")
      refute StatusDetail.valid?(9999, "invalid_credentials")
    end
  end
end
