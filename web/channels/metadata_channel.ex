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
    Logger.debug "got after_join metadata: #{message}, #{donation_link}, topic: #{socket.topic}"
    push socket, "metadata", %{message: message, donation_link: donation_link}
    {:noreply, socket}
  end

  def handle_info({:metadata, message}, socket) do
    push(socket, "metadata", %{message: message})
    {:noreply, socket}
  end

  def handle_info({:donation_link, message}, socket) do
    push(socket, "metadata", %{donation_link: message})
    {:noreply, socket}
  end
end
