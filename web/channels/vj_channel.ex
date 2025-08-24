defmodule Chat.VjChannel do
  use Phoenix.Channel
  require Logger

  def join("vj", _message, socket) do
    {:ok, pubsub} = Redix.PubSub.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))

    Redix.PubSub.subscribe(pubsub, "datafruits:vj", self())

    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, vj_connected } = Redix.command(conn, ["GET", "datafruits:vj"])

    send(self, {:after_join, vj_connected})
    # push socket, "metadata", %{message: message}

    {:ok, socket}
  end

  def handle_info({:after_join, vj_connected}, socket) do
    push socket, "vj", %{vj_connected: vj_connected}
    {:noreply, socket}
  end

  # Avoid throwing an error when a subscribed message enters the channel
  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, socket) do
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info({:redix_pubsub, _redix_id, _ref, :message, %{channel: channel, payload: message}}, socket) do
    Logger.debug "got message from pubsub #{message} on #{channel}"

    push socket, "vj", %{message: message}

    {:noreply, socket}
  end
end
