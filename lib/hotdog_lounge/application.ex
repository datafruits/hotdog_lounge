defmodule HotdogLounge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HotdogLoungeWeb.Telemetry,
      # HotdogLounge.Repo,
      {DNSCluster, query: Application.get_env(:hotdog_lounge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HotdogLounge.PubSub},
      # Start a worker by calling: HotdogLounge.Worker.start_link(arg)
      # {HotdogLounge.Worker, arg},
      # Start to serve requests, typically the last entry
      {Redix, name: :redix, host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD")},
      %{ id: Redix.PubSub,
         start: {Redix.PubSub, :start_link, [[host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"), name: HotdogLoungeWeb.Redix.PubSub]]},
      },

      HotdogLoungeWeb.GlobalRedisSubscriber,
      HotdogLoungeWeb.TreasureDrops,
      {HotdogLoungeWeb.Presence, [name: :presence]},

      HotdogLoungeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HotdogLounge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HotdogLoungeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
