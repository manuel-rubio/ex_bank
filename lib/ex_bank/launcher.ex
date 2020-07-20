defmodule ExBank.Launcher do
  @moduledoc """
  In charge of launch ATM processes via call and provide as response
  the PID of the generated ATM process.
  """
  use GenServer

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
    :noimpl
  end
end
