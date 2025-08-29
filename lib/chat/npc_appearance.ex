defmodule Chat.NpcAppearance do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting Treasure Drops")

    :timer.send_interval(300_000, :npc_appearance)

    {:ok, %{}}
  end

  # NPCs
  # cow
  # serialExperrymentsWayne
  # c-monkey-3
  def handle_info(:npc_appearance, state) do
    if :rand.uniform(10) == 1 do
      npc_name = "cow"
      body = "moo https://datafruits.fm/assets/images/big_cow.png"
      timestamp = :erlang.system_time(:millisecond)

      payload = %{npc_name: npc_name, body: body, timestamp: timestamp}

      Phoenix.PubSub.broadcast(Chat.PubSub, "npc_chat", payload)
    end

    {:noreply, state}
  end
end
