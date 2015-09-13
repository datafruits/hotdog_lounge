defmodule ChatLog do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(ChatLog, [
      {:ets_table_name, :chat_log_table},
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

    [{:ets_table_name, ets_table_name}, {:log_limit, log_limit}] = args

    :ets.new(ets_table_name, [:named_table, :set, :private])

    {:ok, %{log_limit: log_limit, ets_table_name: ets_table_name}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call({log, room, message}, _from, state) do
    %{ets_table_name: ets_table_name} = state
    case log do
      :add_user ->
        result = add_user(room, message, ets_table_name)
      :log_message ->
        result = log_message(room, message, ets_table_name)
      :remove_user ->
        result = remove_user(room, message, ets_table_name)
    end
    {:reply, result, state}
  end

  def handle_call({get, room}, _from, state) do
    %{ets_table_name: ets_table_name} = state
    case get do
      :get_users ->
        result = :ets.lookup(ets_table_name, "#{room}:users")
      :get_logs ->
        result = :ets.lookup(ets_table_name, room)
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

  defp add_user(channel, user, ets_table_name) do
    case :ets.member(ets_table_name, "#{channel}:users") do
      false ->
        Logger.debug "adding first user: #{user}"
        true = :ets.insert(ets_table_name, {"#{channel}:users", [user]})
        {:ok, user}
      true ->
         [{_channel, users}]= :ets.lookup(ets_table_name, "#{channel}:users")
         Logger.debug "adding another user: #{user}"
         :ets.insert(ets_table_name, {"#{channel}:users", [user | users]})
        {:ok, user}
    end
  end

  defp remove_user(channel, user, ets_table_name) do

  end

  def log_message(channel, message) do
    GenServer.call(:chat_log, {:log_message, channel, message})
  end

  defp log_message(channel, message, ets_table_name) do
    case :ets.member(ets_table_name, channel) do
      false ->
        true = :ets.insert(ets_table_name, {channel, [message]})
        {:ok, message}
      true ->
         [{_channel, messages}]= :ets.lookup(ets_table_name, channel)
         :ets.insert(ets_table_name, {channel, [message | messages]})
        {:ok, message}
    end
  end
end
