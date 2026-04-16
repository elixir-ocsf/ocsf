{:ok, event} =
  OCSF.Events.Authentication.logon(
    user: %OCSF.User{uid: "u1", name: "Jane", email_addr: "jane@test.com",
                      org: %OCSF.Organization{uid: "acme"}},
    http_request: %OCSF.HttpRequest{url: "/oauth/token", http_method: "POST",
                                     user_agent: "Mozilla/5.0"},
    src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}},
    service: %OCSF.Service{name: "Cryptr Auth"},
    status: :Success
  )

deny_pii_policy = %OCSF.Policy{
  deny: [:contact, :identity, :network],
  allow: [:identifier, :tenant, :taxonomic, :temporal]
}

allow_all_policy = %OCSF.Policy{
  allow: [:identifier, :tenant, :taxonomic, :temporal, :contact, :identity, :network],
  deny: []
}

Benchee.run(
  %{
    "redact (deny PII)" => fn -> OCSF.Policy.apply(deny_pii_policy, event) end,
    "redact (allow all)" => fn -> OCSF.Policy.apply(allow_all_policy, event) end
  },
  time: 5,
  warmup: 2,
  print: [configuration: false]
)
