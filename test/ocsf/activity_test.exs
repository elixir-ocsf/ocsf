defmodule OCSF.ActivityTest do
  use ExUnit.Case, async: true

  alias OCSF.Activity

  describe "Authentication (3002)" do
    test "values/1 returns all activities" do
      values = Activity.values(3002)
      assert {:"Logon", 1} in values
      assert {:"Logoff", 2} in values
      assert {:"Preauth", 6} in values
      assert {:"Account Switch", 7} in values
      assert {:"Other", 99} in values
    end

    test "label/2 returns the activity name" do
      assert Activity.label(3002, 0) == :"Unknown"
      assert Activity.label(3002, 1) == :"Logon"
      assert Activity.label(3002, 6) == :"Preauth"
      assert Activity.label(3002, 7) == :"Account Switch"
      assert Activity.label(3002, 99) == :"Other"
      assert Activity.label(3002, 42) == nil
    end

    test "uid/2 returns the activity id" do
      assert Activity.uid(3002, :"Logon") == 1
      assert Activity.uid(3002, :"Preauth") == 6
      assert Activity.uid(3002, :"Account Switch") == 7
      assert Activity.uid(3002, :nonexistent) == nil
    end

    test "valid?/2 checks activity existence" do
      assert Activity.valid?(3002, 1)
      assert Activity.valid?(3002, 7)
      refute Activity.valid?(3002, 42)
    end
  end

  test "unknown class_uid returns empty" do
    assert Activity.values(9999) == []
    assert Activity.label(9999, 1) == nil
    assert Activity.uid(9999, :"Logon") == nil
    refute Activity.valid?(9999, 1)
  end
end
