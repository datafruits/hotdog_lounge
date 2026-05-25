defmodule HotdogLoungeWeb.SiteLive do
  use HotdogLoungeWeb, :live_view

  alias HotdogLounge.Streampusher

  @default_timezone "America/Los_Angeles"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    timezone = Map.get(params, "timezone", @default_timezone)
    today = Date.utc_today()

    start_date = parse_date(Map.get(params, "start"), today)
    end_date = parse_date(Map.get(params, "end"), Date.add(start_date, 30))

    socket =
      socket
      |> assign(:timezone, timezone)
      |> assign(:start_date, start_date)
      |> assign(:end_date, end_date)
      |> assign(:grouped_shows, [])
      |> assign(:page_title, page_title(socket.assigns.live_action))

    socket =
      if socket.assigns.live_action == :timetable do
        shows =
          Streampusher.list_scheduled_shows(
            timezone: timezone,
            start_date: start_date,
            end_date: end_date
          )

        grouped = Streampusher.group_shows_by_day(shows, timezone)
        assign(socket, :grouped_shows, grouped)
      else
        socket
      end

    {:noreply, socket}
  end

  defp page_title(:chat), do: "Chat · datafruits.fm"
  defp page_title(:timetable), do: "Timetable · datafruits.fm"
  defp page_title(_), do: "datafruits.fm"

  defp parse_date(nil, default), do: default

  defp parse_date(str, default) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> default
    end
  end

  defp parse_date(_, default), do: default

  defp format_time(nil, _timezone), do: "--:--"

  defp format_time(naive_dt, _timezone) do
    # NOTE: stored datetimes are UTC; proper timezone conversion requires
    # a timezone library (e.g. `tz` or `tzdata`). For this POC, times are
    # displayed as-stored (UTC).
    Calendar.strftime(naive_dt, "%-I:%M %p")
  end
end
