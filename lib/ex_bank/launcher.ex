defmodule ExBank.Launcher do
  @moduledoc """
  In charge of launch ATM processes via call and provide as response
  the PID of the generated ATM process.
  """
  use GenServer

  alias ExBank.Atm

  @server {:global, :atm_launcher}
  @supervisor ExBank.Atm.Supervisor

  @doc """
  Starts the launcher registering as a global process to be
  reachable from other connected nodes.
  """
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @server)
  end

  @impl GenServer
  @doc false
  def init([]) do
    {:ok, %{}}
  end

  @impl GenServer
  @doc false
  def handle_call({:start_atm, caller}, _from, state) do
    {:ok, atm} = DynamicSupervisor.start_child(@supervisor, {Atm, caller})
    {:reply, {:ok, atm}, state}
  end
end
