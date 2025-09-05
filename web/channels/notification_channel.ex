defmodule Chat.NotificationChannel do
  use Phoenix.Channel
  require Logger

  def join("notifications", message, socket) do
    # Redix.PubSub.subscribe(Chat.Redix.PubSub, "datafruits:notifications", self())
    Phoenix.PubSub.subscribe(Chat.PubSub, "notifications")

    send(self(), {:after_join, message})

    {:ok, socket}
  end

  def handle_info({:after_join, _message}, socket) do
    {:noreply, socket}
  end

  # Avoid throwing an error when a subscribed message enters the channel
  # def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, socket) do
  #   {:noreply, socket}
  # end

  # Handle the message coming from the Redis PubSub channel
  def handle_info(%{message: message}, socket) do
    Logger.debug "got message from pubsub #{message} on #{socket.topic}"

    push socket, "notification", %{message: message}

    {:noreply, socket}
  end
end
