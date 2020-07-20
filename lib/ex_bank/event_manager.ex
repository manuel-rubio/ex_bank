defmodule ExBank.EventManager do
  use GenStage

  alias ExBank.Account

  def start_link(args \\ []) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def stop do
    GenStage.stop(__MODULE__)
  end

  @type event() ::
          {:valid_pin, Account.acc_no()}
          | {:invalid_pin, Account.acc_no()}
          | {:withdraw, Account.amount()}
          | {:deposit, Account.amount()}
          | {:transfer, Account.amount()}
          | {:account_blocked, Account.acc_no()}
          | {:account_unblocked, Account.acc_no()}

  @spec notify(event()) :: :ok
  def notify(event) do
    GenStage.cast(__MODULE__, {:notify, event})
  end

  @impl GenStage
  def init([]) do
    {:producer, [], dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_cast({:notify, event}, state) do
    {:noreply, [event], state}
  end

  @impl GenStage
  def handle_demand(demand, state) do
    {:noreply, [], state}
  end
end
