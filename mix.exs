defmodule OCSF.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/docjerem/ocsf"

  def project do
    [
      app: :ocsf,
      version: @version,
      elixir: "~> 1.18",
      elixirc_options: [
        warnings_as_errors: true
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "OCSF",
      description: "Elixir library modelling the Open Cybersecurity Schema Framework (OCSF 1.9)",
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
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
      {:telemetry, "~> 1.0"},

      # test-only
      {:ex_json_schema, "~> 0.10", only: :test, runtime: false},
      {:stream_data, "~> 1.0", only: [:test, :dev], runtime: false},
      {:benchee, "~> 1.3", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # Audit
      {:credo, "~> 1.7", only: [:test, :dev], runtime: false},
      {:blitz_credo_checks, "~> 0.1", only: [:dev, :test], runtime: false},
      {:jump_credo_checks, "~> 0.1", only: [:dev, :test], runtime: false},
      {:oeditus_credo, "~> 0.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.22", only: :dev},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
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

  defp aliases do
    [
      audit: [
        "credo --strict",
        "deps.audit --ignore-file .mix_audit.ignore",
        "deps.unlock --check-unused",
        "dialyzer --format github",
        "doctor --raise",
        "format --check-formatted",
        "sobelow --config --skip",
        &run_hex_audit/1
      ]
    ]
  end

  defp run_hex_audit(_), do: Mix.shell().cmd("mix hex.audit")
end
