defmodule ExBank.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {ExBank.Backend, []},
      {DynamicSupervisor, strategy: :one_for_one, name: ExBank.Atm.Supervisor},
      {ExBank.Launcher, []},
      {ExBank.EventManager, []},
      {ExBank.EventManager.Supervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: ExBank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
