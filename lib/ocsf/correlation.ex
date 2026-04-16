defmodule OCSF.Correlation do
  @moduledoc """
  Business-flow correlation scope.

  Stores a `correlation_uid` in the process dictionary for the duration
  of a function call. Every `OCSF.Event.new/1` call inside the scope
  auto-stamps `metadata.correlation_uid` unless explicitly provided.
  """

  @key :ocsf_correlation_uid

  @doc "Executes `fun` with `uid` as the current correlation UID, restoring the previous value on exit."
  @spec with(String.t(), (-> result)) :: result when result: var
  def with(uid, fun) when is_binary(uid) and is_function(fun, 0) do
    previous = Process.get(@key)
    Process.put(@key, uid)

    try do
      fun.()
    after
      case previous do
        nil -> Process.delete(@key)
        val -> Process.put(@key, val)
      end
    end
  end

  @doc "Returns the current correlation UID, or nil if none is set."
  @spec current() :: String.t() | nil
  def current, do: Process.get(@key)

  @doc "Sets the current correlation UID."
  @spec put(String.t()) :: :ok
  def put(uid) when is_binary(uid) do
    Process.put(@key, uid)
    :ok
  end

  @doc "Clears the current correlation UID."
  @spec clear() :: :ok
  def clear do
    Process.delete(@key)
    :ok
  end
end
