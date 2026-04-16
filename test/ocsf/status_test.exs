defmodule OCSF.StatusTest do
  use ExUnit.Case, async: true

  alias OCSF.Status

  describe "values/0" do
    test "covers OCSF 1.8 status values" do
      values = Status.values()
      assert {:Unknown, 0} in values
      assert {:Success, 1} in values
      assert {:Failure, 2} in values
      assert {:Other, 99} in values
      assert length(values) == 4
    end
  end

  describe "uid/1" do
    test "round-trips with name/1" do
      for {name, uid} <- Status.values() do
        assert Status.uid(name) == uid
      end
    end
  end

  describe "name/1" do
    test "round-trips with uid/1" do
      for {name, uid} <- Status.values() do
        assert Status.name(uid) == name
      end
    end
  end

  describe "valid?/1" do
    test "checks both atoms and integers" do
      assert Status.valid?(:Success)
      assert Status.valid?(1)
      refute Status.valid?(:fake)
      refute Status.valid?(42)
    end
  end

  describe "ecto_values/0" do
    test "matches values/0" do
      assert Status.ecto_values() == Status.values()
    end
  end
end
