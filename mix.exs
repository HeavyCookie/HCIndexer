defmodule HCIndexer.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :hcindexer,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),

      name: "HCIndexer",
      source_url: "https://github.com/HeavyCookie/HCIndexer",
      homepage_url: "https://github.com/HeavyCookie/HCIndexer",
      docs: [
        # main: "HCIndexer", # The main page in the docs
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.13"},
    ]
  end
end
