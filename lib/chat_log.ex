defmodule ChatLog do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    {:ok, client} = Exredis.start_link
    {:ok, _pid} = GenServer.start_link(ChatLog, [
      {:redis_client, client},
      {:log_limit, 100}
    ], opts)
  end

  def get_logs(room) do
    GenServer.call(:chat_log, {:get_logs, room})
  end

  def get_users(room) do
    GenServer.call(:chat_log, {:get_users, room})
  end

  def stop(server) do
    GenServer.call(server, :stop)
  end

  def init(args) do
    [{:redis_client, redis_client}, {:log_limit, log_limit}] = args

    {:ok, %{log_limit: log_limit, redis_client: redis_client}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call({log, room, message}, _from, state) do
    %{redis_client: redis_client} = state
    result = case log do
      :add_user ->
        add_user(room, message, redis_client)
      :log_message ->
        log_message(room, message, redis_client)
      :remove_user ->
        remove_user(room, message, redis_client)
    end
    {:reply, result, state}
  end

  def handle_call({get, room}, _from, state) do
    %{redis_client: redis_client} = state
    result = case get do
      :get_users ->
       redis_client |> Exredis.query(["LRANGE", "#{room}:users", "0", "-1"])
      :get_logs ->
       redis_client |> Exredis.query(["LRANGE", room, "0", "-1"])
    end
    {:reply, result, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:reply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def code_change(_old_version, state, _extra) do
    {:ok, state}
  end

  def add_user(channel, user) do
    GenServer.call(:chat_log, {:add_user, channel, user})
  end

  def remove_user(channel, user) do
    GenServer.call(:chat_log, {:remove_user, channel, user})
  end

  defp add_user(channel, user, redis_client) do
    Logger.debug "adding user: #{user}"
    redis_client |> Exredis.query(["RPUSH", "#{channel}:users", user])
    {:ok, user}
  end

  defp remove_user(channel, user, redis_client) do
    redis_client |> Exredis.query(["LREM", "#{channel}:users", 1, user])
    {:ok, user}
  end

  def log_message(channel, message) do
    GenServer.call(:chat_log, {:log_message, channel, message})
  end

  defp log_message(channel, message, redis_client) do
    redis_client |> Exredis.query(["RPUSH", channel, message])
    {:ok, message}
  end
end
