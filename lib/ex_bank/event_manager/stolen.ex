defmodule ExBank.EventManager.Stolen do
  use GenStage

  alias ExBank.Account

  @producer ExBank.EventManager

  def start_link(args \\ []) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec blocklist() :: [Account.acc_no()]
  def blocklist() do
    GenStage.call(__MODULE__, :blocklist)
  end

  @impl GenStage
  def init([]) do
    tab_ref = :ets.new(:suspicious, [:public, :set])
    {:consumer, tab_ref, subscribe_to: [{@producer, max_demand: 1}]}
  end

  @impl GenStage
  def handle_call(:blocklist, _from, tab_ref) do
    acc_nos = for {acc_no, n} <- :ets.tab2list(tab_ref), n >= 3, do: acc_no
    {:reply, acc_nos, [], tab_ref}
  end

  @impl GenStage
  def handle_events([{:valid_pin, acc_no}], _from, tab_ref) do
    :ets.delete(tab_ref, acc_no)
    {:noreply, [], tab_ref}
  end

  def handle_events([{:invalid_pin, acc_no}], _from, tab_ref) do
    if 3 <= :ets.update_counter(tab_ref, acc_no, 1, {acc_no, 0}) do
      ExBank.Backend.block(acc_no)
    end

    {:noreply, [], tab_ref}
  end

  def handle_events([{:account_blocked, acc_no}], _from, tab_ref) do
    :ets.insert_new(tab_ref, {acc_no, 3})
    {:noreply, [], tab_ref}
  end

  def handle_events([{:account_unblocked, acc_no}], _from, tab_ref) do
    :ets.delete(tab_ref, acc_no)
    {:noreply, [], tab_ref}
  end

  def handle_events([_], _from, tab_ref) do
    {:noreply, [], tab_ref}
  end
end
