{:ok, event} =
  OCSF.Events.Authentication.logon(
    user: %OCSF.User{uid: "u1", name: "Jane", email_addr: "jane@test.com",
                      org: %OCSF.Organization{uid: "acme"}},
    http_request: %OCSF.HttpRequest{url: "/oauth/token", http_method: "POST"},
    src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}},
    service: %OCSF.Service{name: "Cryptr Auth"},
    status: :Success
  )

event_map = OCSF.to_map(event)

Benchee.run(
  %{
    "OCSF.Flatten.flatten/1" => fn -> OCSF.Flatten.flatten(event_map) end
  },
  time: 5,
  warmup: 2,
  print: [configuration: false]
)
