defmodule ExBank.EventManager.Supervisor do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_args) do
    children = [
      {ExBank.EventManager.Alarm, []},
      {ExBank.EventManager.Stolen, []},
      {ExBank.EventManager.Statistics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
