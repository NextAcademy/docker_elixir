defmodule Docker.Mixfile do
  use Mix.Project

  def project do
    [app: :docker_elixir,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Api wrapper for Docker API in Elixir",
     package: package(),
     deps: deps()]
  end

  def package do
    [
      maintainers: ["Ming Xiang Chan"],
      licenses: ["GPL"],
      links: %{"Github" => "https://github.com/NextAcademy/docker_elixir"}
    ]
  end
  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 2.0"},
      {:credo, "~> 0.5"},
      {:httpoison, "~> 0.13"}
    ]
  end
end
