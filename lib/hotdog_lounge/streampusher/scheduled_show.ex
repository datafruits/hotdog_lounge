defmodule HotdogLounge.Streampusher.ScheduledShow do
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}
  @timestamps_opts [type: :naive_datetime]

  schema "scheduled_shows" do
    field :radio_id, :integer
    field :start_at, :naive_datetime
    field :end_at, :naive_datetime
    field :title, :string
    field :description, :string
    field :slug, :string
    field :time_zone, :string
    field :status, :integer, default: 0
    field :dj_id, :integer
    field :playlist_id, :integer
    field :show_series_id, :integer
    field :recording_id, :integer
    field :recurring_interval, :integer, default: 0
    field :recurrence, :boolean, default: false
    field :recurrant_original_id, :integer
    field :is_guest, :boolean, default: false
    field :guest, :string, default: ""
    field :is_live, :boolean, default: false
    field :youtube_link, :string
    field :mixcloud_link, :string
    field :soundcloud_link, :string
    field :image_file_name, :string
    field :image_content_type, :string
    field :image_file_size, :integer
    field :image_updated_at, :naive_datetime

    timestamps()
  end
end
