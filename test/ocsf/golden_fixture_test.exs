defmodule OCSF.GoldenFixtureTest do
  use ExUnit.Case, async: true

  alias OCSF.Events.Authentication

  @fixtures_dir "test/fixtures/ocsf/1.9/authentication"

  defp load_fixture(filename) do
    Path.join(@fixtures_dir, filename)
    |> File.read!()
    |> Jason.decode!()
  end

  describe "logon_success fixture" do
    test "builder output matches golden fixture" do
      {:ok, event} =
        Authentication.logon(
          user: %{
            uid: "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90",
            name: "Jane Doe",
            email_addr: "jane@example.com",
            org: %{uid: "communitiz-app"}
          },
          http_request: %{url: "/oauth/token", http_method: "POST", user_agent: "Mozilla/5.0"},
          src_endpoint: %{ip: {10, 0, 0, 1}},
          service: %{name: "Cryptr Auth"},
          status: :Success,
          severity: :Informational,
          auth_protocol: :"OAUTH 2.0",
          time: ~U[2026-04-15 10:12:03.421Z],
          metadata: %{uid: "018f1a03-2a8f-7b40-9e12-b7aa47bd0c01", product: %{name: "Cryptr"}}
        )

      actual = OCSF.to_map(event) |> stringify_keys()
      expected = load_fixture("logon_success.json")

      assert actual == expected
    end
  end

  describe "logon_failure fixture" do
    test "builder output matches golden fixture" do
      {:ok, event} =
        Authentication.logon(
          user: %{uid: "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90", org: %{uid: "communitiz-app"}},
          service: %{name: "Cryptr Auth"},
          status: :Failure,
          severity: :Medium,
          status_detail: "invalid_credentials",
          time: ~U[2026-04-15 10:12:05.000Z],
          metadata: %{uid: "018f1a03-3b9c-7c50-af23-c8bb58ce1d12", product: %{name: "Cryptr"}}
        )

      actual = OCSF.to_map(event) |> stringify_keys()
      expected = load_fixture("logon_failure.json")

      assert actual == expected
    end
  end

  describe "preauth fixture" do
    test "builder output matches golden fixture" do
      {:ok, event} =
        Authentication.preauth(
          user: %{uid: "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90", org: %{uid: "communitiz-app"}},
          service: %{name: "Cryptr Auth"},
          status: :Success,
          severity: :Informational,
          auth_protocol: :SAML,
          time: ~U[2026-04-15 10:11:59.100Z],
          metadata: %{uid: "018f1a03-1a7e-7a30-8d01-a6aa36ac0b00", product: %{name: "Cryptr"}}
        )

      actual = OCSF.to_map(event) |> stringify_keys()
      expected = load_fixture("preauth.json")

      assert actual == expected
    end
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), stringify_keys(v)} end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(other), do: other
end
