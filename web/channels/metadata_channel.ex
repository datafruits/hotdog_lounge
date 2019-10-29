defmodule Chat.MetadataChannel do
  use Phoenix.Channel
  require Logger

  def join("metadata", message, socket) do
    {:ok, pubsub} = Redix.PubSub.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))

    Redix.PubSub.subscribe(pubsub, "datafruits:metadata", self())

    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, message} = Redix.command(conn, ["GET", "datafruits:metadata"])

    send(self, {:after_join, message})
    # push socket, "metadata", %{message: message}

    {:ok, socket}
  end

  def handle_info({:after_join, message}, socket) do
    push socket, "metadata", %{message: message}
    {:noreply, socket}
  end

  # Avoid throwing an error when a subscribed message enters the channel
  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, socket) do
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info({:redix_pubsub, _redix_id, _ref, :message, %{channel: channel, payload: message}}, socket) do
    Logger.debug "got message from pubsub #{message} on #{channel}"

    push socket, "metadata", %{message: message}

    {:noreply, socket}
  end
end
