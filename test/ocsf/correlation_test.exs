defmodule OCSF.CorrelationTest do
  use ExUnit.Case, async: true

  alias OCSF.Correlation

  test "current/0 returns nil when nothing is set" do
    assert Correlation.current() == nil
  end

  test "put/1 and current/0" do
    Correlation.put("abc-123")
    assert Correlation.current() == "abc-123"
    Correlation.clear()
    assert Correlation.current() == nil
  end

  test "with/2 scopes the correlation_uid" do
    assert Correlation.current() == nil

    result =
      Correlation.with("scope-1", fn ->
        assert Correlation.current() == "scope-1"
        :ok
      end)

    assert result == :ok
    assert Correlation.current() == nil
  end

  test "with/2 restores previous value on exit" do
    Correlation.put("outer")

    Correlation.with("inner", fn ->
      assert Correlation.current() == "inner"
    end)

    assert Correlation.current() == "outer"
    Correlation.clear()
  end

  test "with/2 restores on exception" do
    Correlation.put("before")

    assert_raise RuntimeError, fn ->
      Correlation.with("during", fn ->
        raise "boom"
      end)
    end

    assert Correlation.current() == "before"
    Correlation.clear()
  end

  test "nested with/2 scopes" do
    Correlation.with("level-1", fn ->
      assert Correlation.current() == "level-1"

      Correlation.with("level-2", fn ->
        assert Correlation.current() == "level-2"
      end)

      assert Correlation.current() == "level-1"
    end)

    assert Correlation.current() == nil
  end
end
