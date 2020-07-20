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
    # init stuff!
    state = :no_state?
    {:consumer, state, subscribe_to: [{@producer, max_demand: 1}]}
  end

  @impl GenStage
  def handle_call(_msg, _from, state) do
    # sync call sutff!
    {:reply, :ok, [], state}
  end

  @impl GenStage
  def handle_events([_event], _from, state) do
    # event stuff!
    {:noreply, [], state}
  end
end
