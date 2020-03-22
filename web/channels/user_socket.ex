defmodule Chat.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "rooms:*", Chat.RoomChannel
  channel "metadata", Chat.MetadataChannel
  channel "notifications", Chat.NotificationChannel

  def connect(_params, socket, connect_info) do
    # remote_ip = connect_info.peer_data.address
    remote_ip = Enum.join(Tuple.to_list(connect_info.peer_data.address), ".")
    Logger.debug "remote ip: #{remote_ip}"
    # need to store IP somewhere?
    #
    # dont return OK if banned...
    # if remote_ip in banned_list
    # { :banned, socket }
    # end
    {:ok, assign(socket, :remote_ip, remote_ip)}
  end

  def id(socket) do
    remote_ip = socket.assigns.remote_ip
    "user_socket:#{remote_ip}"
  end
end
