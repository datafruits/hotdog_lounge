# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :hotdog_lounge,
  ecto_repos: [HotdogLounge.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :hotdog_lounge, HotdogLoungeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HotdogLoungeWeb.ErrorHTML, json: HotdogLoungeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HotdogLounge.PubSub,
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
  ],
  live_view: [signing_salt: "4FAn0x0H"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :hotdog_lounge, HotdogLounge.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  hotdog_lounge: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  hotdog_lounge: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :joken, default_signer: System.get_env("JWT_SECRET")

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
