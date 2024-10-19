defmodule Chat.GlobalRedisSubscriber do
  use GenServer
  require Logger

  @redis_channel "datafruits:user_notifications"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting global Redis PubSub subscriber")
    {:ok, _} = Redix.PubSub.subscribe(Chat.Redix.PubSub, @redis_channel, self())
    {:ok, %{}}
  end

  def handle_info({:redix_pubsub, _redix_pid, _ref, :message, %{channel: channel, payload: message}}, state) do
    Logger.debug("Received message from Redis on #{channel}: #{message}")

    # Broadcast the message to Phoenix PubSub so all channels can receive it
    Phoenix.PubSub.broadcast(Chat.PubSub, "user_notifications", %{channel: channel, message: message})

    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, state) do
    Logger.info("Successfully subscribed to Redis channel #{@redis_channel}")
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
