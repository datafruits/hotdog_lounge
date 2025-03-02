defmodule Chat.TreasureDrops do
  use GenServer
  require Logger

  @treasures ["fruit_tickets", "glorp_points", "bonezo"]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting Treasure Drops")

    # TODO adjust
    :timer.send_interval(300_000, :futsu_drop)

    {:ok, %{}}
  end

  def handle_info(:futsu_drop, state) do
    if :rand.uniform(10) == 1 do
      treasure = Enum.random(@treasures)
      amount = if treasure == :bonezo, do: 0, else: :rand.uniform(100)
      uuid = UUID.uuid4()
      timestamp = :erlang.system_time(:millisecond)

      payload = %{treasure: treasure, amount: amount, uuid: uuid, timestamp: timestamp}

      Phoenix.PubSub.broadcast(Chat.PubSub, "treasure_drop", payload)
    end

    {:noreply, state}
  end
end
