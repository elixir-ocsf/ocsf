defmodule OCSF.DoctestTest do
  # Executes the `iex>` examples embedded in the public docs, so the
  # documentation can never drift from the behaviour it describes.
  # Modules whose examples depend on process or application state
  # (OCSF.Correlation, OCSF.EventCodeFormat.get/1 config lookups) are
  # covered by their own test files instead.
  use ExUnit.Case, async: true

  doctest OCSF
  doctest OCSF.Activity
  doctest OCSF.AuthProtocol
  doctest OCSF.Category
  doctest OCSF.Class
  doctest OCSF.Classification
  doctest OCSF.Error
  doctest OCSF.Event
  doctest OCSF.EventCodeFormat
  doctest OCSF.Flatten
  doctest OCSF.Serializer
  doctest OCSF.Severity
  doctest OCSF.Status
  doctest OCSF.StatusDetail
  doctest OCSF.UUID
end
