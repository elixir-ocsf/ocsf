defmodule OCSF.FlattenTest do
  use ExUnit.Case, async: true

  alias OCSF.{Actor, HttpRequest, IamRole, NetworkEndpoint, Organization, Product, Service, User}
  alias OCSF.Events.UserManagement
  alias OCSF.Flatten
  alias OCSF.Test.SchemaValidator

  # Vendored official OCSF 1.9 User Management (3007) schema — the conformance
  # authority the unflatten examples below are checked against. 3007 mirrors the
  # dashboard's user-management audit (top-level `user`, an `iam_roles` list).
  @user_schema SchemaValidator.load_class_schema("user_management")

  # A genuine, richly-populated Assign Roles event: nested objects at 3+ levels
  # (actor.user, user.org, metadata.product) and list fields (iam_roles objects,
  # privileges scalars, metadata.profiles). Built through the real builder, so
  # it is schema-validated by construction.
  defp sample_event do
    {:ok, event} =
      UserManagement.assign_roles(
        user: %User{
          uid: "u-1",
          name: "Alice",
          email_addr: "alice@acme.co",
          org: %Organization{uid: "org-1"}
        },
        iam_roles: [
          %IamRole{name: "admin", uid: "role-1"},
          %IamRole{name: "auditor", uid: "role-9"}
        ],
        privileges: ["policy:write", "policy:read"],
        actor: %Actor{user: %User{uid: "actor-1", name: "Bob"}},
        http_request: %HttpRequest{
          url: "https://acme.co/users/u-1/roles",
          user_agent: "Mozilla/5.0",
          http_method: "POST"
        },
        src_endpoint: %NetworkEndpoint{ip: {10, 0, 0, 1}},
        service: %Service{name: "iam"},
        severity: :Informational,
        status: :Success,
        metadata: %{product: %Product{name: "cryptr"}, profiles: ["cloud"]}
      )

    event
  end

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

  describe "unflatten/1" do
    test "rebuilds nested maps from __ separator" do
      assert %{"user" => %{"uid" => "u1", "name" => "Alice"}} =
               OCSF.Flatten.unflatten(%{"user__uid" => "u1", "user__name" => "Alice"})
    end

    test "keys without a separator pass through" do
      assert %{"severity_id" => 1, "class_uid" => 3002} =
               OCSF.Flatten.unflatten(%{"severity_id" => 1, "class_uid" => 3002})
    end

    test "rebuilds deep nesting (3+ levels)" do
      assert %{"a" => %{"b" => %{"c" => %{"d" => "deep"}}}} =
               OCSF.Flatten.unflatten(%{"a__b__c__d" => "deep"})
    end

    test "preserves nil and list values" do
      assert %{"x" => nil, "y" => [1, 2]} =
               OCSF.Flatten.unflatten(%{"x" => nil, "y" => [1, 2]})
    end

    test "preserves empty map values" do
      assert %{"a" => 1, "b" => %{}} =
               OCSF.Flatten.unflatten(%{"a" => 1, "b" => %{}})
    end

    test "the example event used by these tests is OCSF-conformant" do
      # Guard: the fixture the reconstruction/round-trip tests build on is a
      # valid OCSF 1.9 event per the official vendored schema — so those tests
      # exercise unflatten against real, conformant data, not a made-up shape.
      assert {:ok, []} = SchemaValidator.validate_event(OCSF.to_map(sample_event()), @user_schema)
    end

    test "reconstructs a conformant OCSF event from its sink-column layout" do
      # `flatten(to_map(event))` IS the `ocsf_ecto` column layout: `__`-joined
      # scalar columns (`user__email_addr`, `metadata__product__name`,
      # `src_endpoint__ip`) plus list fields carried verbatim as jsonb
      # (`iam_roles` objects, `privileges` scalars). The `_` inside
      # `email_addr`/`user_agent` stays a literal.
      to_map = OCSF.to_map(sample_event())
      flat = Flatten.flatten(to_map)

      # It really is the flat sink shape.
      assert flat["user__email_addr"] == "alice@acme.co"
      assert flat["metadata__product__name"] == "cryptr"
      assert flat["src_endpoint__ip"] == "10.0.0.1"
      assert flat["privileges"] == ["policy:write", "policy:read"]
      assert is_list(flat["iam_roles"])

      reconstructed = Flatten.unflatten(flat)

      # The reconstructed event is itself schema-conformant...
      assert {:ok, []} = SchemaValidator.validate_event(reconstructed, @user_schema)
      # ...and its JSON is byte-identical to the original serialized event.
      assert Jason.encode!(reconstructed) |> Jason.decode!() ==
               Jason.encode!(to_map) |> Jason.decode!()
    end
  end

  describe "flatten/1 |> unflatten/1 round-trip" do
    test "returns the original map with stringified keys" do
      nested = %{
        "user" => %{"org" => %{"uid" => "acme"}, "email_addr" => "a@b.co"},
        "severity_id" => 1,
        "profiles" => ["p1", "p2"],
        "trace_uid" => nil,
        "empty" => %{}
      }

      assert nested |> Flatten.flatten() |> Flatten.unflatten() == nested
    end

    test "unflatten is a right inverse of flatten on a real serialized event" do
      # Deep `__` nesting (actor.user) and opaque list fields must survive:
      # unflatten then re-flatten is identity, even though `flatten` never
      # descends into lists.
      flat = sample_event() |> OCSF.to_map() |> Flatten.flatten()

      assert Map.has_key?(flat, "actor__user__uid")
      assert Map.has_key?(flat, "metadata__product__name")
      assert flat["privileges"] == ["policy:write", "policy:read"]

      assert flat |> Flatten.unflatten() |> Flatten.flatten() == flat
    end
  end
end
