defmodule HotdogLoungeWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "rooms:*", HotdogLoungeWeb.RoomChannel
  channel "metadata", HotdogLoungeWeb.MetadataChannel
  channel "notifications", HotdogLoungeWeb.NotificationChannel
  channel "user_notifications", HotdogLoungeWeb.UserNotificationChannel

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `HotdogLoungeWeb.RoomChannel`:
  #
  # channel "room:*", HotdogLoungeWeb.RoomChannel
  #
  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.


  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, [define an error handler in the
  # websocket
  # configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(_params, socket, connect_info) do
    env = Application.get_env(:chat, :env)

    Logger.info("env: #{env}")
    remote_ip = case env do
      # currently prod is running on heroku behind proxies, so we must look at the
      # x-forwarded-for header to get the correct ip
      :prod -> ip_from_headers(connect_info.x_headers)
      # otherwise use the peer_data's address in development and test
      _ -> ip_from_peer_data(connect_info.peer_data.address)
    end
    Logger.debug "remote ip: #{remote_ip}"
    {:ok, banned_ips} = Redix.command(:redix, ["SMEMBERS", "datafruits:chat:ips:banned"])
    #
    # dont return OK if banned...
    if Enum.member?(banned_ips, remote_ip) do
      { :banned, socket }
    else
      {:ok, assign(socket, :remote_ip, remote_ip)}
    end
  end

  # Socket IDs are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.HotdogLoungeWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket) do
    remote_ip = socket.assigns.remote_ip
    "user_socket:#{remote_ip}"
  end

  defp ip_from_headers headers do
    { _, remote_ip } = List.keyfind(headers, "x-forwarded-for", 0)
    remote_ip
  end

  defp ip_from_peer_data address do
    Enum.join(Tuple.to_list(address), ".")
  end
end
