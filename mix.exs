defmodule OCSF.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/cryptr-auth/ocsf"

  def project do
    [
      app: :ocsf,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "OCSF",
      description: "Elixir library modelling the Open Cybersecurity Schema Framework (OCSF 1.8)",
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:uuid_v7, "~> 0.6"},

      # test-only
      {:ex_json_schema, "~> 0.10", only: :test, runtime: false},
      {:stream_data, "~> 1.0", only: [:test, :dev], runtime: false},
      {:benchee, "~> 1.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end
