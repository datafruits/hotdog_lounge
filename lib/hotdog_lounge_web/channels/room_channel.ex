defmodule HotdogLoungeWeb.RoomChannel do
  use HotdogLoungeWeb, :channel

  alias HotdogLoungeWeb.Presence
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
    # TODO how long ???
    # :timer.send_interval(60000, :futsu_drop)
    # :timer.send_interval(5000, :futsu_drop)
    send(self(), {:after_join, message})

    Phoenix.PubSub.subscribe(HotdogLounge.PubSub, "bans")
    Phoenix.PubSub.subscribe(HotdogLounge.PubSub, "treasure_drop")

    {:ok, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(%{treasure: treasure, amount: amount, uuid: uuid, timestamp: timestamp}, socket) do
    Logger.debug("sending treasure drop: #{uuid}")
    broadcast! socket, "new:msg", %{user: "Futsu", body: "Coo! I've dropped a treasure package!", is_treasure: true, treasure: treasure, amount: amount, uuid: uuid, timestamp: timestamp, avatarUrl: "https://datafruits.fm/assets/images/emojis//futsu.png", role: "bot"}
    {:noreply, socket}
  end

  # Handle the message coming from the Redis PubSub channel (for chat bans)
  def handle_info(%{message: message}, socket) do
    Logger.debug "got message from pubsub #{message} on #{socket.topic}"

    remote_ip = Enum.at(String.split(message, ":"), 1)
    Logger.debug "banning this IP: #{remote_ip}"
    {:ok, _message} = Redix.command(:redix, ["SADD", "datafruits:chat:ips:banned", remote_ip])

    Logger.debug "broadcasting diconnect"
    # should this be username instead???
    HotdogLoungeWeb.Endpoint.broadcast "user_socket:" <> remote_ip, "disconnect", %{user: message[:user]}
    Logger.debug "done"

    {:noreply, socket}
  end

  def handle_info({:after_join, msg}, socket) do
    Logger.debug("handle_info: #{inspect msg}")
    broadcast! socket, "user:entered", %{user: msg["user"]}
    { :ok, hype_meter_status } = Redix.command(:redix, ["GET", "datafruits:hype_meter_status"])
    Logger.info "hype_meter_status in join: #{hype_meter_status}"
    { :ok, current_limit_break } = Redix.command(:redix, ["GET", "datafruits:limit_break_meter"])
    push socket, "join", %{status: "connected", hype_meter_status: hype_meter_status, limit_break_percentage: current_limit_break}
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
    {:ok, recent_emojis } = Redix.command(:redix, ["ZREVRANGE", "datafruits:emoji:recent:#{msg["user"]}", 0, 19])
    Logger.debug("recent emojis for #{msg["user"]}: #{recent_emojis}")
    push socket, "authorized", %{status: "authorized", user: msg["user"], token: msg["token"], recent_emojis: recent_emojis}
    {:ok, _} = Presence.track(socket, socket.assigns[:user], %{
      online_at: inspect(System.system_time(:second)),
      avatarUrl: msg["avatarUrl"],
      role: msg["role"],
      style: msg["style"],
      pronouns: msg["pronouns"],
      username: msg["user"]
    })
    {:ok, _message} = Redix.command(:redix, ["SADD", "datafruits:chat:sockets", "#{socket.id}:#{msg["user"]}"])
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
    {:ok, _message} = Redix.command(:redix, ["SREM", "datafruits:chat:sockets", "#{socket.id}:#{socket.assigns[:user]}"])
    :ok
  end

  # TODO use :erlang.system_time(:millisecond) for all timestamps
  def handle_in(event, msg, socket) do
    Logger.info "handle_in event: #{inspect event}, #{inspect msg}, #{inspect socket}"
    case event do
      "track_playback" ->
        { :ok, _count } = Redix.command(:redix, ["HINCRBY", "datafruits:track_plays", "#{msg["track_id"]}", 1])
      "new:fruit_tip" ->
        {:ok, total_count} = Redix.command(:redix, ["HINCRBY", "datafruits:fruits", "total", 1])
        {:ok, count} = Redix.command(:redix, ["HINCRBY", "datafruits:fruits", "#{msg["fruit"]}", 1])

        {:ok, _user_count} = Redix.command(:redix, ["HINCRBY", "datafruits:user_fruit_count:#{msg["user"]}", "#{msg["fruit"]}", 1])

        Logger.info "fruit count: #{count}"
        Logger.info msg
        broadcast! socket, "new:fruit_tip", %{user: msg["user"], fruit: msg["fruit"], timestamp: msg["timestamp"], count: count, total_count: total_count}
        if(msg["isFruitSummon"] == true) do
          { :ok, hype_meter_status } = Redix.command(:redix, ["GET", "datafruits:hype_meter_status"])
          Logger.info "hype_meter_status: #{hype_meter_status}"
          if hype_meter_status == "active" do
            Logger.info "sending activate limit break"
            broadcast! socket, "limit_break_activate", %{timestamp: msg["timestamp"]}
            current_limit_break = case Redix.command(:redix, ["GET", "datafruits:limit_break_meter"]) do
              { :ok, value } ->
                Logger.info "got value: #{value}"
                case value do
                  _ when is_integer(value) ->
                    Logger.info("its an integer")
                    value
                  _ when is_float(value) ->
                    Logger.info("its a float ")
                    value
                  "" ->
                    Logger.info("its blank string")
                    0
                  nil ->
                    Logger.info("its nil")
                    0
                  _ when is_binary(value) ->
                    case Float.parse(value) do
                      {parsed_value, _rest} when is_integer(parsed_value) ->
                        Logger.info("parsed as integer from string")
                        parsed_value

                      {parsed_value, _rest} when is_float(parsed_value) ->
                        Logger.info("parsed as float from string")
                        parsed_value

                      :error ->
                        Logger.info("not an integer or float")
                        0
                    end
                end
            end
            Logger.info "current_limit_break: #{current_limit_break}"
            cost = msg["cost"]
            new_limit_break = current_limit_break + (cost * 0.025)
            Logger.info "new_limit_break: #{new_limit_break}"
            Redix.command(:redix, ["SET", "datafruits:limit_break_meter", new_limit_break])
            broadcast! socket, "limit_break_increase", %{user: msg["user"], timestamp: msg["timestamp"], percentage: new_limit_break}
            if new_limit_break >= 100 do
              Logger.info "limit break reached!"
              # trigger combo
              # reset to 0 here
              Redix.command(:redix, ["SET", "datafruits:limit_break_meter", 0.0])
              Redix.command(:redix, ["SET", "datafruits:hype_meter_status", "inactive"])
              # For now pick a random combo ???
              # later, influence combo by which fruits/summons were sent during the limit break
              #   mega cabbage bounce
              #   the glorpening??
              #   fruit sundae spiral
              #   3D strawbur wink
              #   grandpa beans shake
              #   futsu
              #
              #   chat destroyed...
              #   virus popups
              broadcast! socket, "limit_break_reached", %{user: msg["user"], timestamp: msg["timestamp"], percentage: new_limit_break, combo: "fruit-smoothie"}
              broadcast! socket, "new:msg", %{user: "coach", body: "LIMIT BREAK ACTIVATED !!! FRUIT SMOOTHIE!!! #{HotdogLounge.Dingers.random_dingers()}", timestamp: msg["timestamp"]}
              broadcast! socket, "limit_break_deactivate", %{timestamp: msg["timestamp"]}
            end
          end
          broadcast! socket, "new:msg", %{user: "coach", body: "#{msg["user"]} summoned #{msg["fruit"]} !!! #{HotdogLounge.Dingers.random_dingers()}", timestamp: msg["timestamp"]}
        end
        {:reply, {:ok, %{fruit: msg["fruit"]}}, socket}
      "new:msg" ->
        if msg["emojiCounts"] do
          save_emoji_counts msg["emojiCounts"], msg["user"]
        end
        if msg["bot"] == true && msg["avatarUrl"] do
          broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"], role: "bot", avatarUrl: msg["avatarUrl"]}
        else
          broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"], timestamp: msg["timestamp"]}
        end
        HotdogLounge.Discord.send_to_discord msg
        {:reply, {:ok, %{msg: msg["body"]}}, socket}
      "new:msg_with_token" ->
        Logger.debug "#{msg["timestamp"]} -- sending new message from #{msg["user"]} : #{msg["body"]}"
        Logger.debug "token: #{msg["token"]}"
        if msg["emojiCounts"] do
          save_emoji_counts msg["emojiCounts"], msg["user"]
        end
        # check token
        case HotdogLounge.Token.verify_and_validate(msg["token"]) do
          {:ok, claims} ->
            claimed_username = claims["username"]
            if claimed_username == msg["user"] do
              broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"],
                timestamp: msg["timestamp"], role: msg["role"], avatarUrl: msg["avatarUrl"], style: msg["style"], pronouns: msg["pronouns"]}
              HotdogLounge.Discord.send_to_discord msg
              {:reply, {:ok, %{msg: msg["body"]}}, socket}
            end
          {:error, _} ->
            send(self(), {:after_fail_authorize, "bad token"})
            {:noreply, socket}
        end
      # user tries to open treasure
      "treasure:open" ->
        Logger.debug "treasure:open event"
        uuid = msg["uuid"]
        treasure = msg["treasure"]
        amount = msg["amount"]
        user = msg["user"]
        token = msg["token"]
        # TODO auth
        case HotdogLounge.Token.verify_and_validate(token) do
          {:ok, claims} ->
            claimed_username = claims["username"]
            if claimed_username == user do
              broadcast! socket, "treasure:opened", %{user: user, treasure: treasure, amount: amount, uuid: uuid}
              {:noreply, socket}
            end
          {:error, _} ->
            send(self(), {:after_fail_authorize, "bad token"})
            {:noreply, socket}
        end
      # user successfully opened treasure
      "treasure:received" ->
        treasure = msg["treasure"]
        amount = msg["amount"]
        user = msg["user"]
        # TODO auth
        # uuid = msg["uuid"]
        # token = msg["token"]

        message = case treasure do
          "fruit_tickets" -> "@#{user} got #{amount} fruit tickets!"
          "glorp_points" -> "@#{user} got #{amount} glorp points!"
          "bonezo" -> "@#{user} got... BONEZO! Nothing! Better luck next time!"
        end

        Logger.debug "sending new:msg for treasure received..."
        new_uuid = UUID.uuid4()
        timestamp = :erlang.system_time(:millisecond)
        broadcast! socket, "new:msg", %{user: "Futsu", body: message, uuid: new_uuid, timestamp: timestamp, role: "bot", avatarUrl: "https://datafruits.fm/assets/images/emojis//futsu.png"}
        {:noreply, socket}
      # TODO treasure open fail case
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
        {:ok, _message} = Redix.command(:redix, ["SREM", "datafruits:chat:sockets", "#{socket.id}:#{socket.assigns[:user]}"])
        {:reply, {:ok, %{msg: "#{msg["user"]} disconnected"}}, socket}
    end
  end

  defp authorize(username, token) do
    Logger.debug "authorize: #{username}, #{token}"
    case HotdogLounge.Token.verify_and_validate(token) do
      {:ok, claims} ->
        claimed_username = claims["username"]
        if claimed_username == username do
          if String.length(username) > @max_nick_length do
            {:error, "nick too long! :P"}
          else
            {:ok}
          end
        end
      {:error, error_msg } ->
        Logger.debug("error in authorize: #{error_msg}")
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

  defp get_fruit_counts() do
    {:ok, keys} = Redix.command(:redix, ["HKEYS", "datafruits:fruits"])
    counts = Enum.map(keys, fn x -> {:ok, count } = Redix.command(:redix, ["HGET", "datafruits:fruits", x]); {x, count} end) |> Enum.into(%{})
    Logger.info counts
    counts
  end

  defp save_emoji_counts(emojiCounts, user) do
    now = System.system_time(:second)
    Enum.each(emojiCounts, fn {emoji, count} ->
      {:ok, _user_count} = Redix.command(:redix, ["HINCRBY", "datafruits:user_emoji_count:#{user}", "#{emoji}", count])
      Redix.command(:redix, ["ZADD", "datafruits:emoji:recent:#{user}", "#{now}", emoji])
    end)
  end
end
