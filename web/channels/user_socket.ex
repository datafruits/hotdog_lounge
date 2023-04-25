defmodule Chat.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "rooms:*", Chat.RoomChannel
  channel "metadata", Chat.MetadataChannel
  channel "notifications", Chat.NotificationChannel
  channel "user_notifications", Chat.UserNotificationChannel

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
