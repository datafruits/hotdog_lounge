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

    {:ok, pubsub} = Redix.PubSub.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))

    Redix.PubSub.subscribe(pubsub, "datafruits:chat:bans", self())

    {:ok, socket}
  end

  # Avoid throwing an error when a subscribed message enters the channel
  def handle_info({:redix_pubsub, _redix_pid, _ref, :subscribed, _}, socket) do
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel (for chat bans)
  def handle_info({:redix_pubsub, _redix_id, _ref, :message, %{channel: channel, payload: message}}, socket) do
    Logger.debug "got message from pubsub #{message} on #{channel}"

    remote_ip = Enum.at(String.split(message, ":"), 1)
    Logger.debug "banning this IP: #{remote_ip}"
    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, _message} = Redix.command(conn, ["SADD", "datafruits:chat:ips:banned", remote_ip])

    Logger.debug "broadcasting diconnect"
    Chat.Endpoint.broadcast "user_socket:" <> remote_ip, "disconnect", %{}
    Logger.debug "done"

    {:noreply, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info({:after_join, msg}, socket) do
    Logger.debug("handle_info: #{Socket}")
    broadcast! socket, "user:entered", %{user: msg["user"]}
    #logs = ChatLog.get_logs(socket.topic)
    #Logger.info("logs: #{inspect logs}")
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
    Logger.debug "adding user: #{inspect msg}"
    push socket, "authorized", %{status: "authorized", user: msg["user"], token: msg["token"]}
    {:ok, _} = Presence.track(socket, socket.assigns[:user], %{
      online_at: inspect(System.system_time(:second)),
      avatarUrl: msg["avatarUrl"],
      role: msg["role"],
      style: msg["style"],
      pronouns: msg["pronouns"],
      username: msg["user"]
    })
    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, message} = Redix.command(conn, ["SADD", "datafruits:chat:sockets", "#{socket.id}:#{msg["user"]}"])
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
    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, message} = Redix.command(conn, ["SREM", "datafruits:chat:sockets", "#{socket.id}:#{socket.assigns[:user]}"])
    :ok
  end

  def handle_in(event, msg, socket) do
    case event do
      "new:fruit_tip" ->
        broadcast! socket, "new:fruit_tip", %{user: msg["user"], fruit: msg["fruit"], timestamp: msg["timestamp"]}
        # ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
        {:reply, {:ok, %{fruit: msg["fruit"]}}, socket}
      "new:msg" ->
        broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]}
        # ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
        {:reply, {:ok, %{msg: msg["body"]}}, socket}
      "new:msg_with_token" ->
        Logger.debug "#{msg["timestamp"]} -- sending new message from #{msg["user"]} : #{msg["body"]}"
        Logger.debug "token: #{msg["token"]}"
        # check token
        case JWT.verify(msg["token"], %{key: System.get_env("JWT_SECRET")}) do
          {:ok, %{username: claimed_username}} ->
            if claimed_username == msg["user"] do
              broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"],
                timestamp: msg["timestamp"], role: msg["role"], avatarUrl: msg["avatarUrl"], style: msg["style"], pronouns: msg["pronouns"]}
              # ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
              {:reply, {:ok, %{msg: msg["body"]}}, socket}
            end
          {:error, _} ->
            send(self, {:after_fail_authorize, "bad token"})
            {:noreply, socket}
        end
      "authorize_token" ->
        Logger.debug "authorize: #{msg["user"]}, #{msg["token"]}"
        case authorize(msg["user"], msg["token"]) do
          {:ok} ->
            send(self, {:after_authorize, msg})
            socket = socket
              |> assign(:user, msg["user"])
              |> assign(:token, msg["token"])
            {:reply, {:ok, %{msg: "#{msg["user"]} authorized"}}, socket}
          {:error, reason} ->
            send(self, {:after_fail_authorize, reason})
            {:noreply, socket}
        end
      "authorize" ->
        Logger.debug "authorize_anonymous: #{msg["user"]}, #{msg["token"]}"
        case authorize(msg["user"]) do
          {:ok} ->
            send(self, {:after_authorize, msg})
            socket = socket
              |> assign(:user, msg["user"])
            {:reply, {:ok, %{msg: "#{msg["user"]} authorized anonymously"}}, socket}
          {:error, reason} ->
            send(self, {:after_fail_authorize, reason})
            {:noreply, socket}
        end
      "ban" ->
        broadcast! socket, "banned", %{user: msg["user"], timestamp: msg["timestamp"]}
        {:noreply, socket}
      "disconnect" ->
        broadcast! socket, "user:left", %{user: socket.assigns[:user]}
        {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
        {:ok, message} = Redix.command(conn, ["SREM", "datafruits:chat:sockets", "#{socket.id}:#{socket.assigns[:user]}"])
        {:reply, {:ok, %{msg: "#{msg["user"]} disconnected"}}, socket}
    end
  end

  defp authorize(username, token) do
    Logger.debug "authorize: #{username}, #{token}"
    case JWT.verify(token, %{key: System.get_env("JWT_SECRET")})  do
      {:ok, %{username: claimed_username}} ->
        if claimed_username == username do
          if String.length(username) > @max_nick_length do
            {:error, "nick too long! :P"}
          else
            {:ok}
          end
        end
      {:error, _} ->
        {:error, "bad token >:| what is wrong with you"}
    end
  end

  defp authorize(username) do
    Logger.debug "authorize: #{username}"
    # if nick_taken?
    #   {:error, "nick taken! :P"}
    # else
      if String.length(username) > @max_nick_length do
        {:error, "nick too long! :P"}
      else
        {:ok}
      end
    # end
  end
end
