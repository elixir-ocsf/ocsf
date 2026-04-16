{:ok, event} =
  OCSF.Events.Authentication.logon(
    user: %OCSF.User{uid: "u1", name: "Jane", email_addr: "jane@test.com",
                      org: %OCSF.Organization{uid: "acme"}},
    http_request: %OCSF.HttpRequest{url: "/oauth/token", http_method: "POST",
                                     user_agent: "Mozilla/5.0"},
    src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}},
    service: %OCSF.Service{name: "Cryptr Auth"},
    status: :Success,
    severity: :Informational,
    auth_protocol: :"OAUTH 2.0"
  )

event_map = OCSF.to_map(event)
event_json = Jason.encode!(event_map)

Benchee.run(
  %{
    "OCSF.to_map/1" => fn -> OCSF.to_map(event) end,
    "OCSF.to_json/1" => fn -> OCSF.to_json(event) end,
    "Jason.encode!/1 (event)" => fn -> Jason.encode!(event) end,
    "OCSF.Event.from_map/1" => fn -> OCSF.Event.from_map(event_map) end,
    "round-trip (to_map -> from_map)" => fn ->
      event |> OCSF.to_map() |> OCSF.Event.from_map()
    end
  },
  time: 5,
  warmup: 2,
  print: [configuration: false]
)
