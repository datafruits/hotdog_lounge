defmodule HotdogLounge.Repo.Migrations.CreateStreampusherTables do
  use Ecto.Migration

  # Creates the show_series and scheduled_shows tables mirroring the existing
  # Rails (streampusher-api) schema. In production these tables already exist in
  # the shared Postgres database; this migration is here so that the local dev
  # and test databases have the same structure.

  def change do
    create_if_not_exists table(:show_series) do
      add :title, :string, null: false
      add :description, :text
      add :image_file_name, :string
      add :image_file_size, :integer
      add :image_content_type, :string
      add :image_updated_at, :naive_datetime
      add :recurring_interval, :integer, default: 0, null: false
      add :recurring_weekday, :integer, default: 0, null: false
      add :recurring_cadence, :integer
      add :start_time, :naive_datetime, null: false
      add :end_time, :naive_datetime, null: false
      add :start_date, :naive_datetime, null: false
      add :end_date, :naive_datetime
      add :slug, :string
      add :status, :integer, default: 0, null: false
      add :radio_id, :integer, default: 1, null: false
      add :default_playlist_id, :integer
      add :time_zone, :string, default: "UTC", null: false

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists unique_index(:show_series, [:slug])

    create_if_not_exists table(:scheduled_shows, primary_key: false) do
      add :id, :serial, primary_key: true
      add :radio_id, :integer, null: false
      add :start_at, :naive_datetime, null: false
      add :end_at, :naive_datetime, null: false
      add :description, :text
      add :image_file_name, :string
      add :image_content_type, :string
      add :image_file_size, :integer
      add :image_updated_at, :naive_datetime
      add :recurring_interval, :integer, default: 0, null: false
      add :recurrence, :boolean, default: false, null: false
      add :recurrant_original_id, :integer
      add :playlist_id, :integer
      add :dj_id, :integer
      add :title, :string
      add :time_zone, :string
      add :slug, :string
      add :is_guest, :boolean, default: false, null: false
      add :guest, :string, default: "", null: false
      add :is_live, :boolean, default: false, null: false
      add :show_series_id, :integer
      add :status, :integer, default: 0, null: false
      add :recording_id, :integer
      add :youtube_link, :string
      add :mixcloud_link, :string
      add :soundcloud_link, :string

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists index(:scheduled_shows, [:show_series_id])
    create_if_not_exists index(:scheduled_shows, [:start_at])
    create_if_not_exists unique_index(:scheduled_shows, [:slug, :id])
  end
end
