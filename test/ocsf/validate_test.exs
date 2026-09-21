defmodule OCSF.ValidateTest do
  use ExUnit.Case, async: true

  import OCSF.EventFixtures

  describe "validate/1" do
    test "valid Authentication event passes all checks" do
      assert {:ok, _event} = OCSF.validate(valid_event())
    end

    test "missing metadata.uid fails" do
      event = put_in(valid_event().metadata.uid, nil)
      assert {:error, %OCSF.Error{reason: :missing, path: "metadata.uid"}} = OCSF.validate(event)
    end

    test "wrong metadata.version fails" do
      event = put_in(valid_event().metadata.version, "0.9.0")

      assert {:error, %OCSF.Error{reason: :invalid, path: "metadata.version"}} =
               OCSF.validate(event)
    end

    test "missing metadata.product fails" do
      event = put_in(valid_event().metadata.product, nil)

      assert {:error, %OCSF.Error{reason: :missing, path: "metadata.product"}} =
               OCSF.validate(event)
    end

    test "invalid category_uid fails" do
      event = %{valid_event() | category_uid: 999}

      assert {:error, %OCSF.Error{reason: :invalid, path: "category_uid"}} =
               OCSF.validate(event)
    end

    test "class/category mismatch fails" do
      event = %{valid_event() | category_uid: 6}

      assert {:error, %OCSF.Error{reason: :invalid, path: "class_uid"}} = OCSF.validate(event)
    end

    test "wrong type_uid fails" do
      event = %{valid_event() | type_uid: 999_999}

      assert {:error, %OCSF.Error{reason: :invalid, path: "type_uid"}} = OCSF.validate(event)
    end

    test "invalid activity_id fails" do
      event = %{valid_event() | activity_id: 42, type_uid: 3002 * 100 + 42}

      assert {:error, %OCSF.Error{reason: :invalid, path: "activity_id"}} =
               OCSF.validate(event)
    end

    test "invalid status_id fails" do
      event = %{valid_event() | status_id: 42}

      assert {:error, %OCSF.Error{reason: :invalid, path: "status_id"}} = OCSF.validate(event)
    end

    test "non-string status_detail fails" do
      event = %{valid_event() | status_detail: 123}

      assert {:error, %OCSF.Error{reason: :type_mismatch, path: "status_detail"}} =
               OCSF.validate(event)
    end

    test "string status_detail passes" do
      event = %{valid_event() | status_detail: "some detail"}
      assert {:ok, _event} = OCSF.validate(event)
    end

    test "invalid severity_id fails" do
      event = %{valid_event() | severity_id: 42}

      assert {:error, %OCSF.Error{reason: :invalid, path: "severity_id"}} =
               OCSF.validate(event)
    end

    test "missing time fails" do
      event = %{valid_event() | time: nil}
      assert {:error, %OCSF.Error{reason: :missing, path: "time"}} = OCSF.validate(event)
    end

    test "non-UTC time fails" do
      {:ok, non_utc} = DateTime.new(~D[2026-04-15], ~T[10:00:00], "Etc/UTC")
      non_utc = %{non_utc | utc_offset: 3600}
      event = %{valid_event() | time: non_utc}
      assert {:error, %OCSF.Error{reason: :invalid, path: "time"}} = OCSF.validate(event)
    end

    test "missing user for Authentication class fails" do
      event = %{valid_event() | user: nil}
      assert {:error, %OCSF.Error{reason: :missing, path: "user"}} = OCSF.validate(event)
    end

    test "Authentication without service or dst_endpoint violates at_least_one" do
      event = %{valid_event() | service: nil, dst_endpoint: nil}

      assert {:error, %OCSF.Error{reason: :constraint_violated, path: "service|dst_endpoint"}} =
               OCSF.validate(event)
    end

    test "required-field errors take precedence over constraint errors" do
      event = %{valid_event() | user: nil, service: nil}
      assert {:error, %OCSF.Error{reason: :missing, path: "user"}} = OCSF.validate(event)
    end

    test "Authorize Session needs privileges, groups or iam_roles" do
      base = %{valid_event() | class_uid: 3003, type_uid: 300_301, service: nil}

      assert {:error,
              %OCSF.Error{reason: :constraint_violated, path: "privileges|groups|iam_roles"}} =
               OCSF.validate(base)

      assert {:ok, _} = OCSF.validate(%{base | privileges: ["p"]})
      assert {:ok, _} = OCSF.validate(%{base | groups: [%OCSF.Group{uid: "g1"}]})
      assert {:ok, _} = OCSF.validate(%{base | iam_roles: [%OCSF.IamRole{uid: "r1"}]})

      assert {:error, %OCSF.Error{reason: :constraint_violated}} =
               OCSF.validate(%{base | groups: []})
    end

    test "classes without constraints are unaffected" do
      event = %{valid_event() | class_uid: 3007, type_uid: 300_701, service: nil}
      assert {:ok, _} = OCSF.validate(event)
    end
  end
end
