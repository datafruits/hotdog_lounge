defmodule Chat.UserNotificationChannel do
  use Phoenix.Channel
  require Logger

  def join("user_notifications", message, socket) do
    Redix.PubSub.subscribe(Chat.Redix.PubSub, "datafruits:user_notifications", self())

    send(self(), {:after_join, message})

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
    msg = %{"user" => "coach", "body" => "#{message} !!! :O :O :O"}

    push socket, "new:msg", msg
    # TODO should push ID too?
    # push socket, "new:notification", msg
    Logger.debug "sending user_notifications msg to discord"
    send_to_discord msg
    { :noreply, socket }
  end

  defp send_to_discord(msg) do
    Logger.debug "in UserNotificationChannel send_to_discord"
    unless msg["bot"] == true do
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
