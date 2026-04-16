defmodule OCSF.StatusDetail do
  @moduledoc """
  Well-known `status_detail` string constants per OCSF class.

  In OCSF, `status_detail` is a free-form String — any value is valid.
  This module provides well-known constants for consistency and
  discoverability, not enforcement.
  """

  @known_values %{
    3002 => [
      # Success
      "logoff_user_initiated",
      "logoff_other",
      # Failure
      "user_does_not_exist",
      "invalid_credentials",
      "account_disabled",
      "account_locked_out",
      "password_expired",
      "mfa_required",
      # Technical
      "unknown_error"
    ]
  }

  @doc "Returns the list of well-known status_detail strings for a class_uid."
  @spec values(integer) :: [String.t()]
  def values(class_uid), do: Map.get(@known_values, class_uid, [])

  @doc "Returns true if the detail is a well-known value for the class_uid."
  @spec valid?(integer, String.t()) :: boolean
  def valid?(class_uid, detail) when is_binary(detail) do
    detail in values(class_uid)
  end
end
