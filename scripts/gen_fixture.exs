# Regenerates the Authentication golden fixtures that
# test/ocsf/golden_fixture_test.exs compares builder output against.
#
#     mix run scripts/gen_fixture.exs
#
# The target directory follows the OCSF version the library targets
# (test/fixtures/ocsf/<major.minor>/authentication), so a version bump
# never leaves the fixtures behind.

[major, minor, _patch] = String.split(OCSF.version(), ".")

fixtures_dir =
  Path.join([__DIR__, "..", "test", "fixtures", "ocsf", "#{major}.#{minor}", "authentication"])
  |> Path.expand()

File.mkdir_p!(fixtures_dir)

write_fixture = fn filename, event ->
  json = event |> OCSF.to_map() |> Jason.encode!(pretty: true)
  File.write!(Path.join(fixtures_dir, filename), json <> "\n")
  IO.puts("Written #{Path.relative_to_cwd(Path.join(fixtures_dir, filename))}")
end

{:ok, event} =
  OCSF.Events.Authentication.logon(
    user: %{uid: "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90", name: "Jane Doe",
            email_addr: "jane@example.com", org: %{uid: "communitiz-app"}},
    http_request: %{url: "/oauth/token", http_method: "POST", user_agent: "Mozilla/5.0"},
    src_endpoint: %{ip: {10, 0, 0, 1}},
    service: %{name: "Cryptr Auth"},
    status: :Success,
    severity: :Informational,
    auth_protocol: :"OAUTH 2.0",
    time: ~U[2026-04-15 10:12:03.421Z],
    metadata: %{uid: "018f1a03-2a8f-7b40-9e12-b7aa47bd0c01", product: %{name: "Cryptr"}}
  )

write_fixture.("logon_success.json", event)

# Failure case
{:ok, fail_event} =
  OCSF.Events.Authentication.logon(
    user: %{uid: "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90", org: %{uid: "communitiz-app"}},
    service: %{name: "Cryptr Auth"},
    status: :Failure,
    severity: :Medium,
    status_detail: "invalid_credentials",
    time: ~U[2026-04-15 10:12:05.000Z],
    metadata: %{uid: "018f1a03-3b9c-7c50-af23-c8bb58ce1d12", product: %{name: "Cryptr"}}
  )

write_fixture.("logon_failure.json", fail_event)

# Preauth case
{:ok, pre_event} =
  OCSF.Events.Authentication.preauth(
    user: %{uid: "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90", org: %{uid: "communitiz-app"}},
    service: %{name: "Cryptr Auth"},
    status: :Success,
    severity: :Informational,
    auth_protocol: :SAML,
    time: ~U[2026-04-15 10:11:59.100Z],
    metadata: %{uid: "018f1a03-1a7e-7a30-8d01-a6aa36ac0b00", product: %{name: "Cryptr"}}
  )

write_fixture.("preauth.json", pre_event)
