defmodule OCSF.Error do
  @moduledoc """
  Structured error returned by validation and builder functions.

  Carries the reason for the failure, the dotted path to the invalid
  field, and optional details. All functions in this library that can
  fail return `{:error, %OCSF.Error{}}`.

  ## Fields

  - `:reason` — atom describing the failure: `:invalid`, `:missing`,
    `:type_mismatch`, or `:constraint_violated` (an OCSF `at_least_one`
    class constraint, e.g. `service` or `dst_endpoint` on Authentication).
  - `:path` — dotted string pointing at the problematic field
    (e.g. `"user.org.uid"`, `"metadata.version"`). For a constraint the
    candidate fields are joined with `|` (e.g. `"service|dst_endpoint"`).
  - `:details` — map with additional context (expected values, actual
    value, etc.).

  See `OCSF.validate/1` and `OCSF.Events.Authentication` for functions
  that return this struct.
  """

  @type t :: %__MODULE__{
          reason: atom,
          path: String.t(),
          details: map
        }

  defstruct reason: :invalid, path: "", details: %{}

  @doc """
  Create a new error.

  ## Examples

      iex> OCSF.Error.new(:missing, "user.uid")
      %OCSF.Error{reason: :missing, path: "user.uid", details: %{}}

      iex> OCSF.Error.new(:invalid, "severity_id", %{expected: "0..6 or 99", got: 42})
      %OCSF.Error{reason: :invalid, path: "severity_id", details: %{expected: "0..6 or 99", got: 42}}
  """
  @spec new(atom, String.t(), map) :: t
  def new(reason, path, details \\ %{}) do
    %__MODULE__{reason: reason, path: path, details: details}
  end
end
