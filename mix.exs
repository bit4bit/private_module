defmodule PrivateModule.MixProject do
  use Mix.Project

  def project do
    [
      app: :private_module,
      version: "0.1.12",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: dialyzer(),
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/bit4bit/private_module"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp dialyzer() do
    [
      plt_add_apps: [:mix],
      ignore_warnings: ".dialyzer_ignore"
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    """
    PrivateModule is a library that allows to have the concept of private modules,
    where a PrivateModule is a module that can only be used by the parent module.
    """
  end

  defp package do
    [
      name: "private_module",
      files: ~w(lib mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bit4bit/private_module"
      }
    ]
  end

  defp docs do
    [
      main: "PrivateModule",
      extras: ["README.md"],
      source_ref: "v0.1.12",
      source_url: "https://github.com/bit4bit/private_module"
    ]
  end
end
