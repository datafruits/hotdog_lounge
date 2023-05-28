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
    msg = %{user: "coach", body: "#{message} !!! :O :O :O"}

    push socket, "new:msg", msg
    send_to_discord msg
    { :noreply, socket }
  end

  defp send_to_discord(msg) do
    unless msg["bot"] == true do
      avatar_url = if Map.has_key? msg, "avatarUrl" do
        msg["avatarUrl"]
      else
        ""
      end
      json = Poison.encode! %{username: msg["user"], avatar_url: avatar_url, content: msg["body"]}
      :httpc.request :post, {System.get_env("DISCORD_WEBHOOK_URL"), [], 'application/json', json}, [], []
    end
  end

end
