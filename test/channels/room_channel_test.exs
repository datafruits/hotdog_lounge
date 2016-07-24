defmodule Chat.RoomChannelTest do
  use Chat.ChannelCase

  alias Chat.RoomChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(RoomChannel, "rooms:lobby")

    {:ok, socket: socket}
  end

  # test "ping replies with status ok", %{socket: socket} do
  #   ref = push socket, "ping", %{"hello" => "there"}
  #   assert_reply ref, :ok, %{"hello" => "there"}
  # end
  #
  # test "shout broadcasts to rooms:lobby", %{socket: socket} do
  #   push socket, "shout", %{"hello" => "all"}
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end

  test "broadcasts new messages", %{socket: socket} do
    message = %{"user" => "ovenrake", "body" => "i love :hotdogs:", "timestamp" => 201623523}
    ref = push socket, "new:msg", message
    assert_broadcast "new:msg", message
    body = message["body"]
    assert_reply ref, :ok, %{msg: body}
  end

  test "handles authorize"

  test "authorization fails if nick is too long"

  test "authorization fails if nick is taken"

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end
end
