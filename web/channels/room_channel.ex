defmodule Chat.RoomChannel do
  use Phoenix.Channel
  require Logger

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
    push socket, "join", %{status: "connected"}
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    # push socket, "new:msg", %{user: "SYSTEM", body: "ping"}
    {:noreply, socket}
  end

  def handle_info({:after_authorize, msg}, socket) do
    broadcast! socket, "user:authorized", %{user: msg["user"]}
    push socket, "authorized", %{status: "authorized"}
    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug "> leave #{inspect reason}"
    :ok
  end

  def handle_in(event, msg, socket) do
    Logger.debug("handle_in!")
    case event do
      "new:msg" ->
        Logger.debug "sending new message from #{msg["user"]} : #{msg["body"]}"
        broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"]}
        {:reply, {:ok, %{msg: msg["body"]}}, socket}
      "authorize" ->
        Logger.debug "authorize: #{msg["user"]}"
        send(self, {:after_authorize, msg})
        {:reply, {:ok, %{msg: "#{msg["user"]} authorized"}}, assign(socket, :user, msg["user"])}
    end
  end
end
