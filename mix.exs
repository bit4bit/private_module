defmodule PrivateModule.MixProject do
  use Mix.Project

  def project do
    [
      app: :private_module,
      version: "0.1.3",
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
    PrivateModule allows you to define modules that can only be accessed from their parent module,
    enforced at compile time with clear error messages.
    """
  end

  defp package do
    [
      name: "private_module",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bit4bit/private_module",
        "Changelog" => "https://github.com/bit4bit/private_module/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "PrivateModule",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v0.1.1",
      source_url: "https://github.com/bit4bit/private_module"
    ]
  end
end
