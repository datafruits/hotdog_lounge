defmodule HotdogLoungeWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use HotdogLoungeWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders the datafruits site shell layout with a top nav, scrollable main
  content area, and a persistent bottom player region.

  The player container uses `phx-update="ignore"` so LiveView never re-renders
  it, allowing audio to continue playing through patch-based navigation.

  ## Examples

      <Layouts.site_shell flash={@flash} live_action={@live_action}>
        <p>Page content here</p>
      </Layouts.site_shell>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :live_action, :atom, default: nil, doc: "the current live action (:chat or :timetable)"

  slot :inner_block, required: true

  def site_shell(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-df-dark text-white">
      <%!-- Top navigation --%>
      <nav class="flex items-center justify-between px-4 py-2 bg-df-pink text-white flex-shrink-0" id="site-nav">
        <a href="/" class="flex items-center gap-2 hover:opacity-80 transition-opacity">
          <img src={~p"/images/logo.svg"} alt="datafruits.fm" width="32" height="32" class="rounded" />
          <span class="font-bold text-lg tracking-wide">datafruits.fm</span>
        </a>
        <ul class="flex items-center gap-2 text-base font-semibold">
          <li>
            <.link
              patch={~p"/chat"}
              class={[
                "px-3 py-1 rounded transition-colors",
                if(@live_action == :chat, do: "bg-white text-df-pink", else: "hover:bg-white/20")
              ]}
            >
              💬 Chat
            </.link>
          </li>
          <li>
            <.link
              patch={~p"/timetable"}
              class={[
                "px-3 py-1 rounded transition-colors",
                if(@live_action == :timetable, do: "bg-white text-df-pink", else: "hover:bg-white/20")
              ]}
            >
              📅 Timetable
            </.link>
          </li>
        </ul>
      </nav>

      <%!-- Main content area (scrollable, grows to fill space between nav and player) --%>
      <main class="flex-1 overflow-auto" id="main-content">
        {render_slot(@inner_block)}
      </main>

      <%!-- Persistent bottom player region.
           phx-update="ignore": LiveView will not re-render this node on navigation.
           phx-hook="Player": JS hook initializes audio once and handles play/pause/volume. --%>
      <div
        id="player-container"
        phx-update="ignore"
        phx-hook="Player"
        class="flex-shrink-0 bg-df-pink text-white px-4 py-2 flex items-center gap-4 border-t border-white/10"
      >
        <div class="flex items-center gap-3 flex-1">
          <button
            id="player-play-btn"
            class="w-10 h-10 rounded-full bg-white/20 hover:bg-white/30 transition-colors flex items-center justify-center text-lg"
            aria-label="Play/Pause"
          >
            ▶
          </button>
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-sm truncate" id="player-show-title">datafruits.fm</p>
            <p class="text-xs text-white/70 truncate" id="player-dj-name">live radio</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <label for="player-volume" class="sr-only">Volume</label>
          <input
            id="player-volume"
            type="range"
            min="0"
            max="1"
            step="0.05"
            value="0.8"
            class="w-20 accent-white"
            aria-label="Volume"
          />
        </div>
        <audio id="player-audio" src="https://stream.datafruits.fm/stream" preload="none"></audio>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
