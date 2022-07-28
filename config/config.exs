# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :chat, Chat.Endpoint,
  url: [host: "localhost"],
  root: Path.expand("..", __DIR__),
  secret_key_base: "/RjKJmMO6raXPRTq63qTqid1x6lVKTOP+FTxZHfX6Ogd+1xYmH6eZZFhBu1CIwtg",
  debug_errors: false,
  pubsub: [name: Chat.PubSub,
           adapter: Phoenix.PubSub.PG2],
           check_origin: ["//datafruitstest.s3-website-us-east-1.amazonaws.com/", "//localhost:4200", "//localhost:3000", "//localhost:7357", "//datafruits.fm", "//datafruits-fastboot.herokuapp.com/", "//www.datafruits.fm", "https://datafruits.fm", "https://www.datafruits.fm", "https://datafruits-photobooth.glitch.me", "//*.herokuapp.com", "//datafruitsfm.netlify.app/", "https://beta.streampusher.com/", "https://streampusher.com"]

config :chat, env: Mix.env

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :exredis,
  host: "127.0.0.1",
  port: 6379,
  password: "",
  db: 0,
  reconnect: :no_reconnect,
  max_queue: :infinity

config :joken, default_signer: System.get_env("JWT_SECRET")

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
