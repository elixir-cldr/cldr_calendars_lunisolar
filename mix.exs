defmodule Cldr.Calendars.Lunisolar.MixProject do
  use Mix.Project

  @version "1.2.0"

  def project do
    [
      app: :ex_cldr_calendars_lunisolar,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/elixir-cldr/cldr_calendars_lunisolar",
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: ~w(mix ex_cldr_currencies ex_cldr_dates_times ex_cldr_numbers)a,
        ignore_warnings: ".dialyzer_ignore_warnings"
      ]
    ]
  end

  def description do
    """
    Implementation of Lunisolar Chinese, Japanese and Korean calendars for Elixir
    """
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      logo: "logo.png",
      links: links(),
      files: [
        "lib",
        "logo.png",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr_calendars, "~> 2.1"},
      {:ex_cldr_dates_times, "~> 2.10", optional: true, only: [:dev, :test]},

      {:astro, "~> 1.0"},
      {:tz_world, "~> 1.1"},
      {:tz, "~> 0.26", optional: true},
      {:tzdata, "~> 1.1", optional: true},

      {:stream_data, "~> 1.1", only: :test, optional: true},
      {:ex_doc, "~> 0.19", only: [:release, :dev], runtime: false, optional: true},
      {:earmark, "~> 1.4", optional: true, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  def links do
    %{
      "GitHub" =>
        "https://github.com/elixir-cldr/cldr_calendars_lunisolar",
      "Readme" =>
        "https://github.com/elixir-cldr/cldr_calendars_lunisolar/blob/v#{@version}/README.md",
      "Changelog" =>
        "https://github.com/elixir-cldr/cldr_calendars_lunisolar/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def docs do
    [
      formatters: ["html"],
      source_ref: "v#{@version}",
      main: "readme",
      logo: "logo.png",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      skip_undefined_reference_warnings_on: ["changelog"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test", "dev", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "dev", "bench"]
  defp elixirc_paths(_), do: ["lib"]
end
