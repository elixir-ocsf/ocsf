defmodule OCSF.ErrorTest do
  use ExUnit.Case, async: true

  describe "new/2" do
    test "creates error with defaults" do
      error = OCSF.Error.new(:missing, "user.uid")
      assert %OCSF.Error{reason: :missing, path: "user.uid", details: %{}} = error
    end
  end

  describe "new/3" do
    test "creates error with details" do
      error = OCSF.Error.new(:invalid, "severity_id", %{expected: "0..6 or 99", got: 42})

      assert %OCSF.Error{
               reason: :invalid,
               path: "severity_id",
               details: %{expected: "0..6 or 99", got: 42}
             } = error
    end
  end
end
