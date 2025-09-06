defmodule HotdogLoungeWeb.UserNotificationChannel do
  use HotdogLoungeWeb, :channel

  require Logger

  def join("user_notifications", _message, socket) do
    # Subscribe the channel to Phoenix PubSub
    Logger.debug("JOINED user_notifications channel - socket #{inspect(socket)}")
    {:ok, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info(%{message: message}, socket) do
    Logger.debug("Received message from user_notifications topic: #{message} - socket #{inspect(socket)}")

    msg = %{"user" => "coach", "body" => "#{message} !!! #{HotdogLounge.Dingers.random_dingers()}"}

    push socket, "new:msg", msg
    Logger.debug "sending user_notifications msg to discord"
    HotdogLounge.Discord.send_to_discord msg
    { :noreply, socket }
  end
end
