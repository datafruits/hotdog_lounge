defmodule Chat.MetadataChannel do
  use Phoenix.Channel
  require Logger

  def join("metadata", message, socket) do
    Phoenix.PubSub.subscribe(Chat.PubSub, "metadata")
    Phoenix.PubSub.subscribe(Chat.PubSub, "donation_link")

    {:ok, message} = Redix.command(:redix, ["GET", "datafruits:metadata"])

    {:ok, donation_link} = Redix.command(:redix, ["GET", "datafruits:donation_link"])

    send(self(), {:after_join, %{message: message, donation_link: donation_link}})

    {:ok, socket}
  end

  def handle_info({:after_join, %{message: message, donation_link: donation_link}}, socket) do
    push socket, "metadata", %{message: message, donation_link: donation_link}
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info(%{message: message}, socket) do
    Logger.debug "got message from pubsub #{message} on #{socket.topic}"

    case socket.topic do # not sure if this works
      "metadata" ->
        push socket, "metadata", %{message: message}
      "donation_link" ->
        push socket, "metadata", %{donation_link: message}
    end

    {:noreply, socket}
  end
end
