defmodule HotdogLoungeWeb.PageController do
  use HotdogLoungeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
