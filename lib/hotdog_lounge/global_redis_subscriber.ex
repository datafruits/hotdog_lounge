defmodule HotdogLoungeWeb.GlobalRedisSubscriber do
  use GenServer
  require Logger

  @redis_channels [
    "datafruits:user_notifications",
    "datafruits:metadata",
    "datafruits:canonical_metadata",
    "datafruits:notifications",
    "datafruits:donation_link",
    "datafruits:chat:bans"
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting global Redis PubSub subscriber")

    # Subscribe to all defined Redis channels
    Enum.each(@redis_channels, fn channel ->
      {:ok, _} = Redix.PubSub.subscribe(HotdogLoungeWeb.Redix.PubSub, channel, self())
      Logger.info("Subscribed to Redis channel: #{channel}")
    end)

    {:ok, %{}}
  end

  def handle_info({:redix_pubsub, _redix_pid, _ref, :message, %{channel: channel, payload: message}}, state) do
    Logger.debug("Received message from Redis on #{channel}: #{message}")

    # Broadcast the message to Phoenix PubSub based on the channel it came from
    case channel do
      "datafruits:user_notifications" ->
        Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "user_notifications", %{message: message})

      "datafruits:metadata" ->
        Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "metadata", {:message, message})

      "datafruits:canonical_metadata" ->
        Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "canonical_metadata", {:message, message})

      "datafruits:notifications" ->
        Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "notifications", %{message: message})

      "datafruits:donation_link" ->
        Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "donation_link", {:donation_link, message})

      "datafruits:chat:bans" ->
        Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "bans", %{message: message})

      _ ->
        Logger.warning("Received message from unknown channel: #{channel}")
    end

    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, state) do
    # This is just a confirmation of subscription; you may log or handle it if needed
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
