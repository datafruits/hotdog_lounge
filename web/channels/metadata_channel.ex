defmodule Chat.MetadataChannel do
  use Phoenix.Channel
  require Logger

  def join("metadata", message, socket) do
    {:ok, pubsub} = Redix.PubSub.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))

    Redix.PubSub.subscribe(pubsub, "datafruits:metadata", self())
    Redix.PubSub.subscribe(pubsub, "datafruits:donation_link", self())

    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, message} = Redix.command(conn, ["GET", "datafruits:metadata"])

    {:ok, donation_link} = Redix.command(conn, ["GET", "datafruits:donation_link"])

    send(self, {:after_join, %{message: message, donation_link: donation_link}})
    # push socket, "metadata", %{message: message}

    {:ok, socket}
  end

  def handle_info({:after_join, %{message: message, donation_link: donation_link}}, socket) do
    push socket, "metadata", %{message: message, donation_link: donation_link}
    {:noreply, socket}
  end

  # Avoid throwing an error when a subscribed message enters the channel
  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, socket) do
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info({:redix_pubsub, _redix_id, _ref, :message, %{channel: channel, payload: message}}, socket) do
    Logger.debug "got message from pubsub #{message} on #{channel}"

    case channel do
      "datafruits:metadata" ->
        push socket, "metadata", %{message: message}
      "datafruits:donation_link" ->
        push socket, "metadata", %{donation_link: message}
    end

    {:noreply, socket}
  end
end
