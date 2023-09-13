defmodule Chat.PresenceController do
  use Chat.Web, :controller
  alias Chat.Presence

  def index(conn, _params) do
    presence_data = Presence.list("user:")
    json(conn, %{presence: presence_data})
  end
end
