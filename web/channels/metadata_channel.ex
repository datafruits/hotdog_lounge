defmodule Chat.MetadataChannel do
  use Phoenix.Channel
  require Logger

  def join("metadata", message, socket) do
    Phoenix.PubSub.subscribe(Chat.PubSub, "metadata")
    Phoenix.PubSub.subscribe(Chat.PubSub, "canonical_metadata")
    Phoenix.PubSub.subscribe(Chat.PubSub, "donation_link")

    {:ok, message} = Redix.command(:redix, ["GET", "datafruits:metadata"])

    {:ok, donation_link} = Redix.command(:redix, ["GET", "datafruits:donation_link"])

    metadata = canonical_metadata()
    # Logger.debug "the canonical_metadata from hget: #{metadata.inspect}"

    send(self(), {:after_join, %{message: message, donation_link: donation_link, canonical_metadata: metadata}})

    {:ok, socket}
  end

  def handle_info({:after_join, %{message: message, donation_link: donation_link, canonical_metadata: canonical_metadata}}, socket) do
    Logger.debug "got after_join metadata: #{message}, #{donation_link}, topic: #{socket.topic}"
    push socket, "metadata", %{message: message, donation_link: donation_link}
    push(socket, "canonical_metadata", %{message: canonical_metadata})
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

  def handle_info({:canonical_metadata, message}, socket) do
    push(socket, "canonical_metadata", %{message: canonical_metadata()})
    {:noreply, socket}
  end

  defp canonical_metadata() do
    {:ok, canonical_metadata} = Redix.command(:redix, ["HGETALL", "datafruits:canonical_metadata"])
    canonical_metadata |> Enum.chunk_every(2) |> Enum.into(%{}, fn [k, v] -> {k, v} end)
  end
end
