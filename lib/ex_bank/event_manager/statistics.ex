defmodule ExBank.EventManager.Statistics do
  use GenStage

  @producer ExBank.EventManager

  def start_link(args \\ []) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_stats() do
    GenStage.call(__MODULE__, :get_stats)
  end

  @impl GenStage
  def init([]) do
    tab_ref = :ets.new(:statistics, [:public, :set])
    {:consumer, tab_ref, subscribe_to: [{@producer, max_demand: 1}]}
  end

  defp increase(tab_ref, key, step \\ 1) do
    :ets.update_counter(tab_ref, key, step, {key, 0})
  end

  @impl GenStage
  def handle_call(:get_stats, _from, tab_ref) do
    data = :ets.tab2list(tab_ref)

    avg_transfer_amount =
      if transfer = data[:transfer] do
        data[:total_transfer_amount] / transfer
      else
        0
      end

    {:reply, [{:avg_transfer_amount, avg_transfer_amount} | data], [], tab_ref}
  end

  @impl GenStage
  def handle_events([{:withdraw = key, _amount}], _from, tab_ref) do
    increase(tab_ref, key)
    {:noreply, [], tab_ref}
  end

  def handle_events([{:deposit = key, _amount}], _from, tab_ref) do
    increase(tab_ref, key)
    {:noreply, [], tab_ref}
  end

  def handle_events([{:transfer = key, amount}], _from, tab_ref) do
    increase(tab_ref, key)
    increase(tab_ref, :total_transfer_amount, amount)
    {:noreply, [], tab_ref}
  end

  def handle_events([{:account_blocked, _acc_no}], _from, tab_ref) do
    increase(tab_ref, :account_blocked)
    {:noreply, [], tab_ref}
  end

  def handle_events([{:account_unblocked, _acc_no}], _from, tab_ref) do
    increase(tab_ref, :account_unblocked)
    {:noreply, [], tab_ref}
  end

  def handle_events([_], _from, tab_ref) do
    {:noreply, [], tab_ref}
  end
end
