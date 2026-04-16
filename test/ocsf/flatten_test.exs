defmodule OCSF.FlattenTest do
  use ExUnit.Case, async: true

  describe "flatten/1" do
    test "flattens nested maps with __ separator" do
      assert %{"user__uid" => "u1", "user__name" => "Alice"} =
               OCSF.Flatten.flatten(%{user: %{uid: "u1", name: "Alice"}})
    end

    test "top-level keys pass through" do
      assert %{"severity_id" => 1, "class_uid" => 3002} =
               OCSF.Flatten.flatten(%{severity_id: 1, class_uid: 3002})
    end

    test "handles deep nesting (3+ levels)" do
      input = %{a: %{b: %{c: %{d: "deep"}}}}
      assert %{"a__b__c__d" => "deep"} = OCSF.Flatten.flatten(input)
    end

    test "preserves nil values" do
      assert %{"x" => nil} = OCSF.Flatten.flatten(%{x: nil})
    end

    test "empty nested maps are preserved as-is" do
      result = OCSF.Flatten.flatten(%{a: 1, b: %{}})
      assert result == %{"a" => 1, "b" => %{}}
    end
  end
end
