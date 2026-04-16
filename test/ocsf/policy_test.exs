defmodule OCSF.TestStructWithCredential do
  @moduledoc false
  defstruct [:uid, :secret_token]

  def __ocsf_fields__ do
    [
      uid: [class: :identifier, erasable: false],
      secret_token: [class: :credential, erasable: true]
    ]
  end
end

defmodule OCSF.PolicyTest do
  use ExUnit.Case, async: true

  import OCSF.EventFixtures, only: [valid_event_attrs: 0]

  defp valid_event do
    attrs =
      valid_event_attrs()
      |> Keyword.merge(
        user: %OCSF.User{
          uid: "u1",
          name: "Alice",
          email_addr: "alice@example.com",
          org: %OCSF.Organization{uid: "org-1", name: "Acme"},
          type_id: 1
        },
        http_request: %OCSF.HttpRequest{
          url: "https://example.com",
          user_agent: "Mozilla/5.0",
          http_method: "POST"
        },
        src_endpoint: %OCSF.NetworkEndpoint{ip: {10, 0, 0, 1}, port: 443, hostname: "host.local"}
      )

    {:ok, event} = OCSF.Event.new(attrs)
    event
  end

  describe "apply/2" do
    test "denied :contact fields become nil" do
      policy = %OCSF.Policy{
        deny: [:contact],
        allow: [:identifier, :identity, :tenant, :taxonomic]
      }

      redacted = OCSF.Policy.apply(policy, valid_event())
      assert redacted.user.email_addr == nil
    end

    test "denied :identity fields become nil" do
      policy = %OCSF.Policy{
        deny: [:identity],
        allow: [:identifier, :contact, :tenant, :taxonomic]
      }

      redacted = OCSF.Policy.apply(policy, valid_event())
      assert redacted.user.name == nil
    end

    test "denied :network fields become nil" do
      policy = %OCSF.Policy{deny: [:network], allow: [:identifier, :taxonomic, :tenant]}
      redacted = OCSF.Policy.apply(policy, valid_event())
      assert redacted.http_request.url == nil
      assert redacted.http_request.user_agent == nil
      assert redacted.src_endpoint.ip == nil
      assert redacted.src_endpoint.port == nil
      assert redacted.src_endpoint.hostname == nil
      assert redacted.http_request.http_method == "POST"
    end

    test ":credential always denied regardless of policy" do
      policy = %OCSF.Policy{allow: [:credential, :identifier, :taxonomic, :tenant]}

      event =
        valid_event()
        |> Map.put(:user, %OCSF.User{uid: "u1", name: "Alice"})

      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.user.uid == "u1"
    end

    test "allowed fields survive" do
      policy = %OCSF.Policy{
        allow: [:identifier, :tenant, :taxonomic, :contact, :identity, :network],
        deny: []
      }

      redacted = OCSF.Policy.apply(policy, valid_event())
      assert redacted.user.uid == "u1"
      assert redacted.user.name == "Alice"
      assert redacted.user.email_addr == "alice@example.com"
      assert redacted.src_endpoint.ip == {10, 0, 0, 1}
    end

    test "actor.user is redacted recursively" do
      event =
        %{
          valid_event()
          | actor: %OCSF.Actor{
              user: %OCSF.User{uid: "actor-u1", name: "Bob", email_addr: "bob@example.com"}
            }
        }

      policy = %OCSF.Policy{
        deny: [:contact, :identity],
        allow: [:identifier, :tenant, :taxonomic]
      }

      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.actor.user.uid == "actor-u1"
      assert redacted.actor.user.name == nil
      assert redacted.actor.user.email_addr == nil
    end

    test "nil actor remains nil" do
      policy = %OCSF.Policy{deny: [:contact], allow: [:identifier]}
      event = %{valid_event() | actor: nil}
      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.actor == nil
    end

    test "nil service remains nil" do
      policy = %OCSF.Policy{deny: [:taxonomic], allow: [:identifier]}
      event = %{valid_event() | service: nil}
      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.service == nil
    end

    test "service fields are redacted by policy" do
      event = %{
        valid_event()
        | service: %OCSF.Service{name: "auth-svc", uid: "svc-1", version: "2.0"}
      }

      policy = %OCSF.Policy{deny: [:taxonomic], allow: [:identifier]}
      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.service.name == nil
      assert redacted.service.uid == "svc-1"
      assert redacted.service.version == nil
    end

    test "default policy fallback: unmentioned class uses default_policy" do
      # :identity is not in allow or deny, so default_policy(:identity) = :deny should apply
      policy = %OCSF.Policy{allow: [:identifier, :tenant], deny: []}
      event = valid_event()
      redacted = OCSF.Policy.apply(policy, event)
      # :identity default is :deny, so name should be nil
      assert redacted.user.name == nil
      # :contact default is :deny, so email_addr should be nil
      assert redacted.user.email_addr == nil
      # :identifier is in allow, so uid should survive
      assert redacted.user.uid == "u1"
      # :tenant is in allow, so org should survive
      assert redacted.user.org.uid == "org-1"
    end

    test "default policy fallback: :taxonomic defaults to allow" do
      # :taxonomic not in allow or deny, default_policy(:taxonomic) = :allow
      policy = %OCSF.Policy{allow: [:identifier], deny: []}

      event = %{
        valid_event()
        | service: %OCSF.Service{name: "auth-svc", uid: "svc-1"}
      }

      redacted = OCSF.Policy.apply(policy, event)
      # :taxonomic defaults to :allow, so name should survive
      assert redacted.service.name == "auth-svc"
      assert redacted.service.uid == "svc-1"
    end

    test "credential fields are always denied even when in allow list" do
      policy = %OCSF.Policy{
        allow: [:credential, :identifier, :taxonomic, :tenant],
        deny: []
      }

      event = %{
        valid_event()
        | service: %OCSF.TestStructWithCredential{uid: "svc-1", secret_token: "secret123"}
      }

      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.service.uid == "svc-1"
      assert redacted.service.secret_token == nil
    end

    test "dst_endpoint is redacted by policy" do
      event = %{
        valid_event()
        | dst_endpoint: %OCSF.NetworkEndpoint{
            ip: {192, 168, 1, 1},
            port: 443,
            hostname: "api.example.com"
          }
      }

      policy = %OCSF.Policy{deny: [:network], allow: [:identifier]}
      redacted = OCSF.Policy.apply(policy, event)
      assert redacted.dst_endpoint.ip == nil
      assert redacted.dst_endpoint.port == nil
      assert redacted.dst_endpoint.hostname == nil
    end
  end
end
