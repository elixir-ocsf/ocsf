defmodule OCSF.ObjectsTest do
  use ExUnit.Case, async: true

  @object_modules [
    OCSF.Actor,
    OCSF.Feature,
    OCSF.HttpRequest,
    OCSF.Metadata,
    OCSF.NetworkEndpoint,
    OCSF.Organization,
    OCSF.Product,
    OCSF.Service,
    OCSF.User
  ]

  for mod <- @object_modules do
    describe "#{inspect(mod)}" do
      test "__ocsf_fields__/0 returns classified fields matching the struct" do
        [_ | _] = fields = unquote(mod).__ocsf_fields__()

        struct_keys = unquote(mod).__struct__() |> Map.from_struct() |> Map.keys()

        for {name, opts} <- fields do
          assert name in struct_keys,
                 "#{inspect(name)} declared in __ocsf_fields__ but not in struct"

          assert opts[:class] in OCSF.Classification.data_classes(),
                 "field #{name} has invalid class: #{inspect(opts[:class])}"

          assert is_boolean(opts[:erasable]),
                 "field #{name} missing boolean :erasable"
        end
      end
    end
  end
end
