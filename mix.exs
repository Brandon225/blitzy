defmodule Blitzy.MixProject do
  use Mix.Project

  def project do
    [
      app: :blitzy,
      version: "0.0.1",
      elixir: "~> 1.1",
      escript: escript(), #1
      deps: deps()
    ]
  end

  def escript do
    [main_module: Blitzy.CLI]
  end

  # Run "mix help compile.app" to learn about applications.

  def application do
    [
      mod: {Blitzy, []},
      extra_applications: [:logger, :httpoison, :timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.1"},
      {:timex, "~> 3.3"},
      {:tzdata, "~> 0.1.8", override: true}
    ]
  end
end

