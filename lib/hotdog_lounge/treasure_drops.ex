defmodule HotdogLoungeWeb.TreasureDrops do
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
    # TODO increase rate during limit break
    if :rand.uniform(10) == 1 do
      treasure = Enum.random(@treasures)

      base_amount = if treasure == "bonezo", do: 0, else: :rand.uniform(100)
      {amount, double_bonus} =
        case treasure do
          "fruit_tickets" ->
            if :rand.uniform(20) == 1 do
              Logger.info("DOUBLE fruit tix!")
              {base_amount * 2, true}
            else
              {base_amount, false}
            end
          "glorp_points" ->
            if :rand.uniform(50) == 1 do
              Logger.info("DOUBLE glorp points!")
              {base_amount * 2, true}
            else
              {base_amount, false}
            end
          "bonezo" ->
            Logger.info("double bonezo???")
            {base_amount, false}
          _ ->
            Logger.info("what kinda treasure is it")
            {base_amount, false}
        end
      {:ok, hype_meter_status} = Redix.command(:redix, ["GET", "datafruits:hype_meter_status"])
      amount = if hype_meter_status == "active" do
        round(amount * 1.75)
      else
        amount
      end

      uuid = UUID.uuid4()
      timestamp = :erlang.system_time(:millisecond)

      payload = %{treasure: treasure, amount: amount, uuid: uuid, timestamp: timestamp, double_bonus: double_bonus}
      Logger.info("sending payload...#{inspect(payload)}")

      Phoenix.PubSub.broadcast(HotdogLounge.PubSub, "treasure_drop", payload)
    end

    {:noreply, state}
  end
end
