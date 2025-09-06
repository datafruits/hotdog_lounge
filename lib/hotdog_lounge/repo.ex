defmodule HotdogLounge.Repo do
  use Ecto.Repo,
    otp_app: :hotdog_lounge,
    adapter: Ecto.Adapters.Postgres
end
