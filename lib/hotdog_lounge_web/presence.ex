defmodule HotdogLoungeWeb.Presence do
  use Phoenix.Presence, otp_app: :hotdog_lounge,
                        pubsub_server: HotdogLounge.PubSub
end
