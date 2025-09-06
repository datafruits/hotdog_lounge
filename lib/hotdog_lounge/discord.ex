defmodule HotdogLounge.Discord do
  require Logger

  def send_to_discord(msg) do
    env = Application.get_env(:hotdog_lounge, :env)
    Logger.info("env: #{inspect(env)}")

    if env == :prod and msg["bot"] != true do
      avatar_url = Map.get(msg, "avatarUrl", "")

      json =
        Jason.encode!(%{
          username: msg["user"],
          avatar_url: avatar_url,
          content: msg["body"]
        })

      Logger.debug("json for discord webhook")
      Logger.debug(json)

      :httpc.request(
        :post,
        {System.get_env("DISCORD_WEBHOOK_URL"), [], 'application/json', json},
        [],
        []
      )
    else
      Logger.info("skipping discord webhook (env=#{inspect(env)}, bot=#{inspect(msg["bot"])})")
    end
  end
end
