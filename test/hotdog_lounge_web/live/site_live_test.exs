defmodule HotdogLoungeWeb.SiteLiveTest do
  use HotdogLoungeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "/chat" do
    test "renders the site shell with top nav and player", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      assert has_element?(view, "#site-nav")
      assert has_element?(view, "#player-container")
    end

    test "renders chat placeholder content", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      assert has_element?(view, "#chat-container")
    end

    test "nav contains a chat link in the site nav", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # The chat nav link is present and rendered inside the site nav
      assert has_element?(view, "#site-nav a[href='/chat']")
    end

    test "player container has phx-update=ignore for persistence", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/chat")

      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(id="player-container")
    end

    test "player container has phx-hook=Player for JS initialization", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/chat")

      assert html =~ ~s(phx-hook="Player")
    end
  end

  describe "/timetable" do
    test "renders the site shell with top nav and player", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/timetable")

      assert has_element?(view, "#site-nav")
      assert has_element?(view, "#player-container")
    end

    test "renders timetable container", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/timetable")

      assert has_element?(view, "#timetable-container")
    end

    test "accepts start, end, and timezone query params", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, ~p"/timetable?start=2026-01-01&end=2026-01-31&timezone=America%2FLos_Angeles")

      assert has_element?(view, "#timetable-container")
    end

    test "shows 'no scheduled shows' message when no results", %{conn: conn} do
      # Use a date range far in the past where no shows exist in test DB
      {:ok, view, _html} =
        live(conn, ~p"/timetable?start=2000-01-01&end=2000-01-02")

      assert has_element?(view, "p", "No scheduled shows found")
    end

    test "nav contains a timetable link in the site nav", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/timetable")

      assert has_element?(view, "#site-nav a[href='/timetable']")
    end
  end

  describe "patch navigation (player persistence)" do
    test "player remains mounted when patch-navigating from /chat to /timetable", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      assert has_element?(view, "#chat-container")
      assert has_element?(view, "#player-container")

      # Patch navigate to timetable — player DOM stays (phx-update=ignore)
      assert {:ok, view, _html} = live(view, ~p"/timetable")

      assert has_element?(view, "#timetable-container")
      assert has_element?(view, "#player-container")
    end

    test "player remains mounted when patch-navigating from /timetable to /chat", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/timetable")

      assert has_element?(view, "#timetable-container")
      assert has_element?(view, "#player-container")

      # Patch navigate to chat — player DOM stays (phx-update=ignore)
      assert {:ok, view, _html} = live(view, ~p"/chat")

      assert has_element?(view, "#chat-container")
      assert has_element?(view, "#player-container")
    end
  end
end
