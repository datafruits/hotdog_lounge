defmodule Chat.UserSocket do
  use Phoenix.Socket

  channel "rooms:*", Chat.RoomChannel

  transport :websocket, Phoenix.Transports.WebSocket,
    check_origin: ["//datafruitstest.s3-website-us-east-1.amazonaws.com/", "//localhost:4200", "//datafruits.fm"]
  transport :longpoll, Phoenix.Transports.LongPoll,
    check_origin: ["//datafruitstest.s3-website-us-east-1.amazonaws.com/", "//localhost:4200", "//datafruits.fm"]

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
