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
    send(self(), {:after_join, message})

    Phoenix.PubSub.subscribe(Chat.PubSub, "bans")

    {:ok, socket}
  end

  # Handle the message coming from the Redis PubSub channel (for chat bans)
  def handle_info(%{message: message}, socket) do
    Logger.debug "got message from pubsub #{message} on #{socket.topic}"

    remote_ip = Enum.at(String.split(message, ":"), 1)
    Logger.debug "banning this IP: #{remote_ip}"
    {:ok, _message} = Redix.command(:redix, ["SADD", "datafruits:chat:ips:banned", remote_ip])

    Logger.debug "broadcasting diconnect"
    # should this be username instead???
    Chat.Endpoint.broadcast "user_socket:" <> remote_ip, "disconnect", %{user: message[:user]}
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
    push socket, "fruit_counts", get_fruit_counts()
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
    {:ok, message} = Redix.command(:redix, ["SADD", "datafruits:chat:sockets", "#{socket.id}:#{msg["user"]}"])
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
    {:ok, message} = Redix.command(:redix, ["SREM", "datafruits:chat:sockets", "#{socket.id}:#{socket.assigns[:user]}"])
    :ok
  end

  def handle_in(event, msg, socket) do
    case event do
      "track_playback" ->
        { :ok, count } = Redix.command(:redix, ["HINCRBY", "datafruits:track_plays", "#{msg["track_id"]}", 1])
      "new:fruit_tip" ->
        {:ok, total_count} = Redix.command(:redix, ["HINCRBY", "datafruits:fruits", "total", 1])
        {:ok, count} = Redix.command(:redix, ["HINCRBY", "datafruits:fruits", "#{msg["fruit"]}", 1])
        # might need user id here?
        {:ok, user_count} = Redix.command(:redix, ["HINCRBY", "datafruits:user_fruit_count:#{msg["user"]}", "#{msg["fruit"]}", 1])
        Logger.info "fruit count: #{count}"
        broadcast! socket, "new:fruit_tip", %{user: msg["user"], fruit: msg["fruit"], timestamp: msg["timestamp"], count: count, total_count: total_count}
        if(msg["isFruitSummon"] == true) do
          broadcast! socket, "new:msg", %{user: "coach", body: "#{msg["user"]} summoned #{msg["fruit"]} !!! #{Chat.Dingers.random_dingers()}", timestamp: msg["timestamp"]}
        end
        # ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
        {:reply, {:ok, %{fruit: msg["fruit"]}}, socket}
      "new:msg" ->
        if msg["bot"] == true && msg["avatarUrl"] do
          broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"], role: "bot", avatarUrl: msg["avatarUrl"]}
        else
          broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]}
        end
        send_to_discord msg
        # ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
        {:reply, {:ok, %{msg: msg["body"]}}, socket}
      "new:msg_with_token" ->
        Logger.debug "#{msg["timestamp"]} -- sending new message from #{msg["user"]} : #{msg["body"]}"
        Logger.debug "token: #{msg["token"]}"
        # check token
        case Chat.Token.verify_and_validate(msg["token"]) do
          {:ok, claims} ->
            claimed_username = claims["username"]
            if claimed_username == msg["user"] do
              broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"],
                timestamp: msg["timestamp"], role: msg["role"], avatarUrl: msg["avatarUrl"], style: msg["style"], pronouns: msg["pronouns"]}
              send_to_discord msg
              # ChatLog.log_message(socket.topic, %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]})
              {:reply, {:ok, %{msg: msg["body"]}}, socket}
            end
          {:error, _} ->
            send(self(), {:after_fail_authorize, "bad token"})
            {:noreply, socket}
        end
      "authorize_token" ->
        Logger.debug "authorize: #{msg["user"]}, #{msg["token"]}"
        case authorize(msg["user"], msg["token"]) do
          {:ok} ->
            send(self(), {:after_authorize, msg})
            socket = socket
              |> assign(:user, msg["user"])
              |> assign(:token, msg["token"])
            {:reply, {:ok, %{msg: "#{msg["user"]} authorized"}}, socket}
          {:error, reason} ->
            send(self(), {:after_fail_authorize, reason})
            {:noreply, socket}
        end
      "authorize" ->
        Logger.debug "authorize_anonymous: #{msg["user"]}, #{msg["token"]}"
        case authorize(msg["user"]) do
          {:ok} ->
            send(self(), {:after_authorize, msg})
            socket = socket
              |> assign(:user, msg["user"])
            {:reply, {:ok, %{msg: "#{msg["user"]} authorized anonymously"}}, socket}
          {:error, reason} ->
            send(self(), {:after_fail_authorize, reason})
            {:noreply, socket}
        end
      "ban" ->
        broadcast! socket, "banned", %{user: msg["user"], timestamp: msg["timestamp"]}
        {:noreply, socket}
      "disconnect" ->
        broadcast! socket, "user:left", %{user: socket.assigns[:user]}
        {:ok, message} = Redix.command(:redix, ["SREM", "datafruits:chat:sockets", "#{socket.id}:#{socket.assigns[:user]}"])
        {:reply, {:ok, %{msg: "#{msg["user"]} disconnected"}}, socket}
    end
  end

  defp authorize(username, token) do
    Logger.debug "authorize: #{username}, #{token}"
    case Chat.Token.verify_and_validate(token) do
      {:ok, claims} ->
        claimed_username = claims["username"]
        if claimed_username == username do
          if String.length(username) > @max_nick_length do
            {:error, "nick too long! :P"}
          else
            {:ok}
          end
        end
      {:error, _} ->
        {:error, "bad token :| check your fruitiverse donglficiation"}
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

  defp send_to_discord(msg) do
    unless msg["bot"] == true do
      avatar_url = if Map.has_key? msg, "avatarUrl" do
        msg["avatarUrl"]
      else
        ""
      end
      json = Poison.encode! %{username: msg["user"], avatar_url: avatar_url, content: msg["body"]}
      Logger.debug "json for disord webhook"
      Logger.debug json
      :httpc.request :post, {System.get_env("DISCORD_WEBHOOK_URL"), [], 'application/json', json}, [], []
    end
  end

  defp get_fruit_counts() do
    {:ok, keys} = Redix.command(:redix, ["HKEYS", "datafruits:fruits"])
    counts = Enum.map(keys, fn x -> {:ok, count } = Redix.command(:redix, ["HGET", "datafruits:fruits", x]); {x, count} end) |> Enum.into(%{})
    Logger.info counts
    counts
  end
end
