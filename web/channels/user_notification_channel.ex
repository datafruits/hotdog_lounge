defmodule Chat.UserNotificationChannel do
  use Phoenix.Channel
  require Logger

  def join("user_notifications", message, socket) do
    # Subscribe the channel to Phoenix PubSub
    Logger.debug("JOINED user_notifications channel - socket #{inspect(socket)}")
    {:ok, socket}
  end

  # Handle the message coming from the Redis PubSub channel
  def handle_info(%{message: message}, socket) do
    Logger.debug("Received message from user_notifications topic: #{message} - socket #{inspect(socket)}")

    msg = %{"user" => "coach", "body" => "#{message} !!! #{Chat.Dingers.random_dingers()}"}

    push socket, "new:msg", msg
    Logger.debug "sending user_notifications msg to discord"
    send_to_discord msg
    { :noreply, socket }
  end

  defp send_to_discord(msg) do
    Logger.debug "in UserNotificationChannel send_to_discord"
    Logger.info("env: #{Config.config_env()}")
    unless msg["bot"] == true && Config.config_env() == :prod do
      avatar_url = if Map.has_key? msg, "avatarUrl" do
        msg["avatarUrl"]
      else
        ""
      end
      Logger.debug "sending http request for discord webhook"
      Logger.debug msg
      json = Poison.encode! %{username: msg["user"], avatar_url: avatar_url, content: msg["body"]}
      Logger.debug "json for disord webhook"
      Logger.debug json
      :httpc.request :post, {System.get_env("DISCORD_WEBHOOK_URL"), [], 'application/json', json}, [], []
    end
  end

end
