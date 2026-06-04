defmodule HotdogLoungeWeb.RoomChannelTest do
  use HotdogLoungeWeb.ChannelCase, async: true

  alias HotdogLoungeWeb.RoomChannel

  test "rejects new:msg bodies longer than the max message length" do
    socket = %Phoenix.Socket{topic: "rooms:lobby"}

    message = %{
      "user" => "tony",
      "body" => String.duplicate("a", 1001),
      "timestamp" => 1_716_426_000_000
    }

    assert {:reply, {:error, %{error: "message too long", max_message_length: 1000}}, ^socket} =
             RoomChannel.handle_in("new:msg", message, socket)
  end

  test "rejects new:msg_with_token bodies longer than the max message length" do
    socket = %Phoenix.Socket{topic: "rooms:lobby"}

    message = %{
      "user" => "tony",
      "body" => String.duplicate("a", 1001),
      "timestamp" => 1_716_426_000_000,
      "token" => "signed-token"
    }

    assert {:reply, {:error, %{error: "message too long", max_message_length: 1000}}, ^socket} =
             RoomChannel.handle_in("new:msg_with_token", message, socket)
  end
end
