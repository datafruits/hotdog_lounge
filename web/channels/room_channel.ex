defmodule Chat.RoomChannel do
  use Phoenix.Channel
  alias Chat.Presence
  require Logger

  @max_nick_length 30

  @doc """
  Authorize socket to subscribe and broadcast events on this channel & topic

  Possible Return Values

  `{:ok, socket}` to authorize subscription for channel for requested topic

  `:ignore` to deny subscription/broadcast on this channel
  for the requested topic
  """
  def join("rooms:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    :timer.send_interval(5000, :ping)
    send(self, {:after_join, message})

    {:ok, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info({:after_join, msg}, socket) do
    broadcast! socket, "user:entered", %{user: msg["user"]}
    logs = ChatLog.get_logs(socket.topic)
    Logger.info("logs: #{inspect logs}")
    push socket, "join", %{status: "connected"}
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    # push socket, "new:msg", %{user: "SYSTEM", body: "ping"}
    {:noreply, socket}
  end

  def handle_info({:after_authorize, msg}, socket) do
    broadcast! socket, "user:authorized", %{user: msg["user"]}
    Logger.debug "adding user: #{msg["user"]}"
    push socket, "authorized", %{status: "authorized", user: msg["user"]}
    {:ok, _} = Presence.track(socket, socket.assigns[:user], %{
      online_at: inspect(System.system_time(:second))
    })
    {:noreply, socket}
  end

  def handle_info({:after_fail_authorize, reason}, socket) do
    push socket, "notauthorized", %{status: "not authorized", error: reason}
    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.info "> leave #{inspect reason}"
    Logger.info "> leave #{inspect socket}"
    Logger.info "> leave #{socket.assigns[:user]}"
    broadcast! socket, "user:left", %{user: socket.assigns[:user]}
    :ok
  end

  def handle_in(event, msg, socket) do
    Logger.debug("handle_in!")
    case event do
      "new:msg" ->
        Logger.debug "#{msg["timestamp"]} -- sending new message from #{msg["user"]} : #{msg["body"]}"
        broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]}
        ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
        {:reply, {:ok, %{msg: msg["body"]}}, socket}
      "authorize" ->
        Logger.debug "authorize: #{msg["user"]}"
        if String.length(msg["user"]) > @max_nick_length do
          send(self, {:after_fail_authorize, "nick too long! :P"})
          {:noreply, socket}
        else
          send(self, {:after_authorize, msg})
          {:reply, {:ok, %{msg: "#{msg["user"]} authorized"}}, assign(socket, :user, msg["user"])}
        end
    end
  end
end
