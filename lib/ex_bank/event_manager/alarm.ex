defmodule ExBank.EventManager.Alarm do
  use GenStage

  @producer ExBank.EventManager

  def start_link(args \\ []) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenStage
  def init([]) do
    {:consumer, [], subscribe_to: [{@producer, max_demand: 1}]}
  end

  @impl GenStage
  def handle_events([{:account_blocked, acc_no}], _from, state) do
    :alarm_handler.set_alarm({acc_no, :account_blocked})
    {:noreply, [], state}
  end

  def handle_events([{:account_unblocked, acc_no}], _from, state) do
    :alarm_handler.clear_alarm(acc_no)
    {:noreply, [], state}
  end

  def handle_events([_], _from, state) do
    {:noreply, [], state}
  end
end
