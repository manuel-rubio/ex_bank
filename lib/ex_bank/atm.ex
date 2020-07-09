defmodule ExBank.Atm do
  @moduledoc """
  ATM state machine. It's going to be responsible to
  interact with the backend handling the input from the
  ATM web interface and sending the output to be handled.
  """
  use GenStateMachine, callback_mode: :state_functions

  alias ExBank.{Account, Backend}

  defmodule Data do
    @moduledoc """
    Data module stores the information for the state
    and persist it inside of the loop (the loop data).
    """
    @type t() :: %ExBank.Atm.Data{
            acc_no: nil | Account.acc_no(),
            pin: String.t(),
            digits: String.t()
          }

    defstruct acc_no: nil,
              pin: "",
              digits: ""
  end

  @spec start_link() :: :gen_statem.start_ret()
  @doc """
  Starts the state machine.
  """
  def start_link() do
    GenStateMachine.start_link(__MODULE__, [])
  end

  @impl GenStateMachine
  @doc false
  def init([]) do
    {:ok, :idle, %Data{}}
  end

  @type action() :: :withdraw | :balance | :statement

  @type incoming_requests() ::
          {:card_inserted, Account.acc_no()}
          | {:digit, String.t()}
          | :enter
          | {:selection, action()}
          | :clear
          | :cancel
          | :stop

  @type call() :: {:call, GenServer.from()}

  @type state_return() :: :gen_statem.event_handler_result(Data.t())

  @doc """
  Implements the "idle" state.
  """
  def idle({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  @doc """
  Implements the "get_pin" state.
  """
  def get_pin({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  @doc """
  Implements "selection"
  """
  def selection({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  @doc """
  Implements "withdraw".
  """
  def withdraw({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end
end
