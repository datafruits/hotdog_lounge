defmodule Chat.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "rooms:*", Chat.RoomChannel
  channel "metadata", Chat.MetadataChannel
  channel "notifications", Chat.NotificationChannel

  def connect(_params, socket, connect_info) do
    remote_ip = Enum.join(Tuple.to_list(connect_info.peer_data.address), ".")
    Logger.debug "remote ip: #{remote_ip}"
    {:ok, conn} = Redix.start_link(host: System.get_env("REDIS_HOST"), password: System.get_env("REDIS_PASSWORD"))
    {:ok, banned_ips} = Redix.command(conn, ["LRANGE", "datafruits:chat:ips:banned", 0, -1])
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
end
