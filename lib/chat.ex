defmodule Chat do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Chat.Endpoint, []),
      # Here you could define other workers and supervisors as children
      # worker(Chat.Worker, [arg1, arg2, arg3]),
      #worker(ChatLog, [[name: :chat_log]]),
      {Redix, name: :redix, host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD")},
      %{
        id: Chat.Redix.PubSub,
        start: {Redix.PubSub, :start_link, [[host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"), name: Chat.Redix.PubSub]]},
      },
      worker(Chat.Presence, [[name: :presence]])
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
