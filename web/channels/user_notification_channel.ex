defmodule Chat.UserNotificationChannel do
  use Phoenix.Channel
  require Logger

  def join("user_notifications", message, socket) do
    Redix.PubSub.subscribe(Chat.Redix.PubSub, "datafruits:user_notifications", self())

    send(self, {:after_join, message})

    {:ok, socket}
  end

  def handle_info({:after_join, message}, socket) do
    {:noreply, socket}
  end

  # Avoid throwing an error when a subscribed message enters the channel
  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, socket) do
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info({:redix_pubsub, _redix_id, _ref, :message, %{channel: channel, payload: message}}, socket) do
    Logger.debug "got message from user notifications pubsub #{message} on #{channel}"

    push socket, "new:msg", %{user: "coach", body: "#{message} !!! :O :O :O"}
    { :noreply, socket }
  end
end
