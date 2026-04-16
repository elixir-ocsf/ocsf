defmodule OCSF.EventCodeFormatTest do
  use ExUnit.Case, async: true

  import OCSF.EventFixtures, only: [valid_event_attrs: 0]

  defp test_event do
    attrs =
      valid_event_attrs()
      |> Keyword.merge(
        metadata: %OCSF.Metadata{
          uid: "test-uid",
          version: "1.8.0",
          product: %OCSF.Product{
            name: "Test",
            feature: %OCSF.Feature{name: "Magic Link"}
          }
        },
        time: ~U[2026-04-15 10:00:00Z],
        user: %OCSF.User{uid: "u1"}
      )

    {:ok, event} = OCSF.Event.new(attrs)
    event
  end

  describe "normalize/1" do
    test "lowercases, replaces non-alnum with _, collapses, trims" do
      assert OCSF.EventCodeFormat.normalize("Authentication") == "authentication"
      assert OCSF.EventCodeFormat.normalize("Magic Link") == "magic_link"
      assert OCSF.EventCodeFormat.normalize("User-Login!") == "user_login"
      assert OCSF.EventCodeFormat.normalize("  Multiple---Dashes  ") == "multiple_dashes"
      assert OCSF.EventCodeFormat.normalize("__leading_trailing__") == "leading_trailing"
    end
  end

  describe "generate/2" do
    test "joins resolved fields with separator" do
      format = %OCSF.EventCodeFormat{
        fields: [[:class_name], [:activity_name]],
        separator: ":"
      }

      assert OCSF.EventCodeFormat.generate(format, test_event()) == "authentication:logon"
    end

    test "skips nil fields" do
      format = %OCSF.EventCodeFormat{
        fields: [[:class_name], [:nonexistent_path], [:activity_name]],
        separator: ":"
      }

      assert OCSF.EventCodeFormat.generate(format, test_event()) == "authentication:logon"
    end

    test "returns nil when all fields are nil" do
      format = %OCSF.EventCodeFormat{
        fields: [[:nonexistent], [:also_nonexistent]],
        separator: ":"
      }

      assert OCSF.EventCodeFormat.generate(format, test_event()) == nil
    end

    test "virtual paths resolve (class_name, activity_name)" do
      format = %OCSF.EventCodeFormat{
        fields: [[:category_name], [:class_name], [:activity_name], [:severity], [:status]],
        separator: ":"
      }

      result = OCSF.EventCodeFormat.generate(format, test_event())

      assert result ==
               "identity_access_management:authentication:logon:informational:success"
    end

    test "physical paths resolve (metadata.product.feature.name)" do
      format = %OCSF.EventCodeFormat{
        fields: [[:class_name], [:metadata, :product, :feature, :name], [:activity_name]],
        separator: ":"
      }

      assert OCSF.EventCodeFormat.generate(format, test_event()) ==
               "authentication:magic_link:logon"
    end

    test "physical path halts at non-map value" do
      format = %OCSF.EventCodeFormat{
        fields: [[:metadata, :uid, :nonexistent]],
        separator: ":"
      }

      # metadata.uid is a string, trying to access .nonexistent should yield nil
      assert OCSF.EventCodeFormat.generate(format, test_event()) == nil
    end

    test "virtual paths return nil for unknown UIDs" do
      {:ok, event} =
        OCSF.Event.new(
          metadata: %OCSF.Metadata{
            uid: "test-uid",
            version: "1.8.0",
            product: %OCSF.Product{name: "Test"}
          },
          time: ~U[2026-04-15 10:00:00Z],
          category_uid: 3,
          class_uid: 3002,
          type_uid: 300_201,
          activity_id: 1,
          severity_id: 1,
          status_id: 1,
          user: %OCSF.User{uid: "u1"}
        )

      # Override UIDs to invalid values to trigger nil branches
      event = %{
        event
        | class_uid: 99_999,
          activity_id: 98,
          category_uid: 99_999,
          severity_id: 98,
          status_id: 98
      }

      format = %OCSF.EventCodeFormat{
        fields: [[:class_name], [:activity_name], [:category_name], [:severity], [:status]],
        separator: ":"
      }

      assert OCSF.EventCodeFormat.generate(format, event) == nil
    end
  end

  describe "get/1" do
    test "returns nil for unconfigured format" do
      assert OCSF.EventCodeFormat.get(:nonexistent) == nil
    end

    test "returns format struct when configured" do
      Application.put_env(:ocsf, :event_code,
        formats: %{
          test_format: %{fields: [[:class_name], [:activity_name]], separator: "-"}
        }
      )

      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)

      format = OCSF.EventCodeFormat.get(:test_format)
      assert %OCSF.EventCodeFormat{} = format
      assert format.fields == [[:class_name], [:activity_name]]
      assert format.separator == "-"
    end
  end

  describe "default_format/0" do
    test "returns nil when not configured" do
      Application.delete_env(:ocsf, :event_code)
      assert OCSF.EventCodeFormat.default_format() == nil
    end

    test "returns configured default format name" do
      Application.put_env(:ocsf, :event_code, default_format: :my_format)
      on_exit(fn -> Application.delete_env(:ocsf, :event_code) end)
      assert OCSF.EventCodeFormat.default_format() == :my_format
    end
  end

  describe "normalize/1 edge cases" do
    test "normalizes atom values" do
      assert OCSF.EventCodeFormat.normalize(:SomeAtom) == "someatom"
    end

    test "normalizes non-string non-atom values via to_string" do
      assert OCSF.EventCodeFormat.normalize(42) == "42"
    end

    test "normalizes empty string" do
      assert OCSF.EventCodeFormat.normalize("") == ""
    end
  end
end
