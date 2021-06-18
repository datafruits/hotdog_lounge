defmodule Chat.Mixfile do
  use Mix.Project

  def project do
    [app: :chat,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Chat, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :logger, :exredis]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support", "test/lib"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 1.5"},
     {:phoenix_pubsub, "~> 2.0"},
     {:phoenix_html, "~> 2.11"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:phoenix_ecto, "~> 4.1"},
     {:ecto_sql, "~> 3.4"},
     {:postgrex, ">= 0.0.0"},
     {:jason, "~> 1.0"},
     {:exredis, ">= 0.2.4"},
     {:redix, ">= 0.0.0"},
     {:plug_cowboy, "~> 2.1"},
     {:plug, "~> 1.7"},
     {:json_web_token, "~> 0.2.5"}]
  end
end
