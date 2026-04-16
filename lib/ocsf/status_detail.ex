defmodule OCSF.StatusDetail do
  @moduledoc """
  Well-known `status_detail` string constants per OCSF class.

  In OCSF, `status_detail` is a free-form String -- any value is valid.
  This module provides well-known constants for consistency and
  discoverability, not enforcement.

  > **Note:** `status_detail` is a free-form string in OCSF, not an
  > enum. This module only defines well-known values used by convention.

  ## Values (Authentication, class 3002)

  **Success outcomes:** `"logoff_user_initiated"`, `"logoff_other"`

  **Failure outcomes:** `"user_does_not_exist"`, `"invalid_credentials"`,
  `"account_disabled"`, `"account_locked_out"`, `"password_expired"`,
  `"mfa_required"`

  **Technical:** `"unknown_error"`

  See `OCSF.Status` for the `status_id` enum.
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

  @doc """
  Return the list of well-known `status_detail` strings for a `class_uid`.

  Returns an empty list if the class has no well-known values.

  ## Examples

      iex> "invalid_credentials" in OCSF.StatusDetail.values(3002)
      true

      iex> OCSF.StatusDetail.values(9999)
      []
  """
  @spec values(integer) :: [String.t()]
  def values(class_uid), do: Map.get(@known_values, class_uid, [])

  @doc """
  Return true if the detail is a well-known value for the `class_uid`.

  ## Examples

      iex> OCSF.StatusDetail.valid?(3002, "invalid_credentials")
      true

      iex> OCSF.StatusDetail.valid?(3002, "custom_detail")
      false
  """
  @spec valid?(integer, String.t()) :: boolean
  def valid?(class_uid, detail) when is_binary(detail) do
    detail in values(class_uid)
  end
end
