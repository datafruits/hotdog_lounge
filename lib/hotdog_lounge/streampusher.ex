defmodule HotdogLounge.Streampusher do
  @moduledoc """
  Context for Streampusher data, reading directly from the shared Postgres database.

  Scheduled show datetimes (`start_at`, `end_at`) are stored in UTC in the Rails DB.
  The `timezone` parameter is accepted for compatibility with the Rails API interface
  and used for display purposes. Proper timezone-aware conversion (using a library like
  `tzdata` or `tz`) can be added later; for now, date parameters are treated as UTC
  boundary dates.
  """

  import Ecto.Query

  alias HotdogLounge.Repo
  alias HotdogLounge.Streampusher.ScheduledShow
  alias HotdogLounge.Streampusher.ShowSeries

  # show_series status enum: 0 = active, 1 = archived, 2 = disabled
  @active_status 0

  @doc """
  Lists scheduled shows filtered to match the Rails API behavior:
  - Only shows with a show_series_id (not nil)
  - Joined show_series where status == 0 (active)
  - start_at >= start of start_date (UTC midnight)
  - end_at <= end of end_date (UTC end-of-day)
  - Ordered by start_at ASC

  Accepts options:
  - `start_date` - Date (defaults to today UTC)
  - `end_date` - Date (defaults to start_date + 30 days)
  - `timezone` - String timezone name (accepted for API compatibility; stored but
    not yet used for conversion — requires a timezone library such as `tz` or `tzdata`)
  """
  def list_scheduled_shows(opts \\ []) do
    start_date = Keyword.get(opts, :start_date, Date.utc_today())
    end_date = Keyword.get(opts, :end_date, Date.add(start_date, 30))

    start_dt = NaiveDateTime.new!(start_date, ~T[00:00:00])
    end_dt = NaiveDateTime.new!(end_date, ~T[23:59:59])

    ScheduledShow
    |> where([s], not is_nil(s.show_series_id))
    |> join(:inner, [s], ss in ShowSeries, on: ss.id == s.show_series_id)
    |> where([_s, ss], ss.status == @active_status)
    |> where([s], s.start_at >= ^start_dt)
    |> where([s], s.end_at <= ^end_dt)
    |> order_by([s], asc: s.start_at)
    |> select([s, ss], %{show: s, series: ss})
    |> Repo.all()
  end

  @doc """
  Groups scheduled shows by day (using UTC date of start_at).
  Returns a list of `{date, [show_pairs]}` tuples ordered by date ascending.
  """
  def group_shows_by_day(show_pairs, _timezone \\ "America/Los_Angeles") do
    show_pairs
    |> Enum.group_by(fn %{show: show} ->
      NaiveDateTime.to_date(show.start_at)
    end)
    |> Enum.sort_by(fn {date, _} -> date end, Date)
  end
end
