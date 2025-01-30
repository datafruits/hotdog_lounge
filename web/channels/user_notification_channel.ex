defmodule Chat.UserNotificationChannel do
  use Phoenix.Channel
  require Logger

  def join("user_notifications", message, socket) do
    # Subscribe the channel to Phoenix PubSub
    Logger.debug("JOINED user_notifications channel - socket #{inspect(socket)}")
    Phoenix.PubSub.subscribe(Chat.PubSub, "user_notifications")

    {:ok, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info(%{message: message}, socket) do
    Logger.debug("Received message from user_notifications topic: #{message} - socket #{inspect(socket)}")

    msg = %{"user" => "coach", "body" => "#{message} !!! #{Chat.Dingers.random_dingers()}"}

    broadcast! socket, "new:msg", msg
    { :noreply, socket }
  end
end
