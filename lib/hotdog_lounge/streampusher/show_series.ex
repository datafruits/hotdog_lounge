defmodule HotdogLounge.Streampusher.ShowSeries do
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}
  @timestamps_opts [type: :naive_datetime]

  schema "show_series" do
    field :title, :string
    field :description, :string
    field :status, :integer, default: 0
    field :slug, :string
    field :radio_id, :integer
    field :time_zone, :string, default: "UTC"
    field :recurring_interval, :integer, default: 0
    field :recurring_weekday, :integer, default: 0
    field :recurring_cadence, :integer
    field :start_time, :naive_datetime
    field :end_time, :naive_datetime
    field :start_date, :naive_datetime
    field :end_date, :naive_datetime
    field :default_playlist_id, :integer
    field :image_file_name, :string
    field :image_content_type, :string
    field :image_file_size, :integer
    field :image_updated_at, :naive_datetime

    timestamps()
  end
end
