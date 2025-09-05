# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# Configures the endpoint
config :chat, Chat.Endpoint,
  url: [host: "localhost"],
  root: Path.expand("..", __DIR__),
  secret_key_base: "/RjKJmMO6raXPRTq63qTqid1x6lVKTOP+FTxZHfX6Ogd+1xYmH6eZZFhBu1CIwtg",
  debug_errors: false,
  pubsub_server: Chat.PubSub,
  check_origin: [
    "//datafruitstest.s3-website-us-east-1.amazonaws.com/",
    "//localhost:4200",
    "//192.168.0.30:4200",
    "//localhost:3000",
    "//localhost:7357",
    "//datafruits.fm",
    "//datafruits-fastboot.herokuapp.com/",
    "//www.datafruits.fm",
    "https://datafruits.fm",
    "https://www.datafruits.fm",
    "https://datafruits-photobooth.glitch.me",
    "//*.netlify.app",
    "//datafruitsfm.netlify.app/",
    "https://beta.streampusher.com/",
    "https://streampusher.com",
    "//datafruits-mojiplode.glitch.me",
    "//*.glitch.me",
    "//*.ondigitalocean.app"
  ]

config :chat, env: config_env()

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :joken, default_signer: System.get_env("JWT_SECRET")

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
