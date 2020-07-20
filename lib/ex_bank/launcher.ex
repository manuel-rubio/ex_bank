defmodule ExBank.Launcher do
  @moduledoc """
  In charge of launch ATM processes via call and provide as response
  the PID of the generated ATM process.
  """
  use GenServer

  alias ExBank.Atm

  @server {:global, :atm_launcher}

  @doc """
  Starts the launcher registering as a global process to be
  reachable from other connected nodes.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @server)
  end

  @impl GenServer
  @doc false
  def init([]) do
    {:ok, %{}}
  end

  @impl GenServer
  @doc false
  def handle_call({:start_atm, caller}, _from, state) do
    {:ok, atm} = Atm.start_link(caller)
    {:reply, {:ok, atm}, state}
  end
end
