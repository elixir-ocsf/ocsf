base_opts = [
  user: %OCSF.User{uid: "u1", name: "Jane", email_addr: "jane@test.com",
                    org: %OCSF.Organization{uid: "acme"}},
  http_request: %OCSF.HttpRequest{url: "/oauth/token", http_method: "POST"},
  src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}},
  service: %OCSF.Service{name: "Cryptr Auth"},
  status: :Success,
  severity: :Informational,
  auth_protocol: :"OAUTH 2.0"
]

Benchee.run(
  %{
    "Authentication.logon/1" => fn -> OCSF.Events.Authentication.logon(base_opts) end,
    "Authentication.logoff/1" => fn -> OCSF.Events.Authentication.logoff(base_opts) end,
    "Authentication.preauth/1" => fn -> OCSF.Events.Authentication.preauth(base_opts) end
  },
  time: 5,
  warmup: 2,
  print: [configuration: false]
)
