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
  Starts the state machine. A PID must be provided to know where to
  send async events (for the interface) when they are needed to be
  reported.
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

  # Note that use GenStateMachine.from/0 spec or :gen_statem.from/0 fails
  @type call() :: {:call, GenServer.from()}

  @type state_return() :: :gen_statem.event_handler_result(Data.t())

  @doc """
  Implements the "idle" state.
  """
  def idle({:call, from}, {:card_inserted, acc_no}, data) do
    case Backend.get(acc_no) do
      {:error, :no_account} ->
        actions = [{:reply, from, :invalid_card}]
        {:keep_state_and_data, actions}

      {:account, _acc_no, _pin, _name, _balance, _trans} ->
        data = %Data{data | acc_no: acc_no}
        actions = [{:reply, from, :ask_pin}]
        {:next_state, :get_pin, data, actions}
    end
  end

  def idle({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def idle({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  @doc """
  Implements the "get_pin" state.
  """
  def get_pin({:call, from}, {:digit, _}, %Data{digits: d}) when byte_size(d) >= 4 do
    actions = [{:reply, from, :no_more_digits}]
    {:keep_state_and_data, actions}
  end

  def get_pin({:call, from}, {:digit, d}, data) do
    actions = [{:reply, from, :more_digits}]
    data = %Data{data | digits: data.digits <> d}
    {:keep_state, data, actions}
  end

  def get_pin({:call, from}, :enter, data) do
    if Backend.pin_valid?(data.acc_no, data.digits) do
      data = %Data{data | digits: "", pin: data.digits}
      actions = [{:reply, from, :choose_option}]
      {:next_state, :selection, data, actions}
    else
      actions = [{:reply, from, :invalid_pin}]
      {:keep_state_and_data, actions}
    end
  end

  def get_pin({:call, from}, :clear, data) do
    data = %Data{data | digits: ""}
    actions = [{:reply, from, :ok}]
    {:keep_state, data, actions}
  end

  def get_pin({:call, from}, :cancel, _data) do
    data = %Data{}
    actions = [{:reply, from, :ok}]
    {:next_state, :idle, data, actions}
  end

  def get_pin({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def get_pin({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  @doc """
  Implements "selection"
  """
  def selection({:call, from}, {:selection, :balance}, data) do
    {:ok, balance} = Backend.balance(data.acc_no, data.pin)
    actions = [{:reply, from, {:balance, balance}}]
    {:keep_state_and_data, actions}
  end

  def selection({:call, from}, {:selection, :statement}, data) do
    {:ok, transactions} = Backend.transactions(data.acc_no, data.pin)
    actions = [{:reply, from, {:statement, transactions}}]
    {:keep_state_and_data, actions}
  end

  def selection({:call, from}, {:selection, :withdraw}, data) do
    actions = [{:reply, from, :ask_amount}]
    {:next_state, :withdraw, data, actions}
  end

  def selection({:call, from}, :cancel, _data) do
    data = %Data{}
    actions = [{:reply, from, :ok}]
    {:next_state, :idle, data, actions}
  end

  def selection({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def selection({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  @doc """
  Implements "withdraw".
  """
  def withdraw({:call, from}, {:digit, _}, %Data{digits: d}) when byte_size(d) >= 6 do
    actions = [{:reply, from, :no_more_digits}]
    {:keep_state_and_data, actions}
  end

  def withdraw({:call, from}, {:digit, d}, data) do
    actions = [{:reply, from, :more_digits}]
    data = %Data{data | digits: data.digits <> d}
    {:keep_state, data, actions}
  end

  def withdraw({:call, from}, :enter, data) do
    amount = String.to_integer(data.digits)

    case Backend.withdrawal(data.acc_no, data.pin, amount) do
      :ok ->
        actions = [{:reply, from, :success_withdraw}]
        {:next_state, :selection, data, actions}

      {:error, :balance} ->
        actions = [{:reply, from, :no_balance}]
        {:keep_state_and_data, actions}
    end
  end

  def withdraw({:call, from}, :clear, data) do
    data = %Data{data | digits: ""}
    actions = [{:reply, from, :ok}]
    {:keep_state, data, actions}
  end

  def withdraw({:call, from}, :cancel, _data) do
    data = %Data{}
    actions = [{:reply, from, :ok}]
    {:next_state, :idle, data, actions}
  end

  def withdraw({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def withdraw({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end
end
