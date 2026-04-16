defmodule OCSF.Correlation do
  @moduledoc """
  Business-flow correlation scope.

  Stores a `correlation_uid` in the process dictionary for the duration
  of a function call. Every OCSF event created inside the scope
  auto-stamps `metadata.correlation_uid` unless explicitly provided.
  This enables tracing multiple events that belong to the same
  business-level flow (e.g. a login attempt spanning preauth, logon,
  and MFA steps).

  ## Examples

      OCSF.Correlation.with("corr-123", fn ->
        # all events created here get correlation_uid = "corr-123"
        OCSF.Correlation.current()
        #=> "corr-123"
      end)

  See `OCSF.Metadata` for how `correlation_uid` is persisted on events.
  """

  @key :ocsf_correlation_uid

  @doc """
  Execute `fun` with `uid` as the current correlation UID, restoring the previous value on exit.

  ## Examples

      iex> OCSF.Correlation.with("abc", fn -> OCSF.Correlation.current() end)
      "abc"
  """
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

  @doc """
  Return the current correlation UID, or `nil` if none is set.

  ## Examples

      iex> OCSF.Correlation.current()
      nil
  """
  @spec current() :: String.t() | nil
  def current, do: Process.get(@key)

  @doc """
  Set the current correlation UID.

  ## Examples

      iex> OCSF.Correlation.put("test-uid")
      :ok
  """
  @spec put(String.t()) :: :ok
  def put(uid) when is_binary(uid) do
    Process.put(@key, uid)
    :ok
  end

  @doc """
  Clear the current correlation UID.

  ## Examples

      iex> OCSF.Correlation.clear()
      :ok
  """
  @spec clear() :: :ok
  def clear do
    Process.delete(@key)
    :ok
  end
end
