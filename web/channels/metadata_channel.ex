defmodule Chat.MetadataChannel do
  use Phoenix.Channel
  require Logger

  def join("metadata", message, socket) do
    Redix.PubSub.subscribe(Chat.Redix.PubSub, "datafruits:metadata", self())
    Redix.PubSub.subscribe(Chat.Redix.PubSub, "datafruits:donation_link", self())

    {:ok, message} = Redix.command(:redix, ["GET", "datafruits:metadata"])

    {:ok, donation_link} = Redix.command(:redix, ["GET", "datafruits:donation_link"])

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
