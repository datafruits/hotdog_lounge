defmodule Chat.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "rooms:*", Chat.RoomChannel
  channel "metadata", Chat.MetadataChannel
  channel "notifications", Chat.NotificationChannel

  def connect(_params, socket, connect_info) do
    remote_ip = connect_info.peer_data.address
    # need to store IP somewhere?
    #
    # dont return OK if banned...
    # if remote_ip in banned_list
    # { :banned, socket }
    # end
    {:ok, socket}
  end

  def id(socket) do
    "user_socket:#{socket.assigns.remote_ip}"
  end
end
