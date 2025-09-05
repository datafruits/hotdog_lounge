defmodule Chat do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do

    children = [
      # Start the endpoint when the application starts
      Chat.Endpoint,
      {Phoenix.PubSub, [name: Chat.PubSub, adapter: Phoenix.PubSub.PG2]},
      {Redix, name: :redix, host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD")},
      {Redix.PubSub, host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"), name: Chat.Redix.PubSub},

      Chat.GlobalRedisSubscriber,
      Chat.TreasureDrops,
      {Chat.Presence, [name: :presence]}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Chat.Endpoint.config_change(changed, removed)
    :ok
  end
end
