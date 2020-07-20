defmodule ExBank.Atm do
  @moduledoc """
  ATM state machine. It's going to be responsible to
  interact with the backend handling the input from the
  ATM web interface and sending the output to be handled.
  """
  use GenStateMachine, callback_mode: :state_functions, restart: :temporary

  alias ExBank.{Account, Backend}

  @default_timeout 10_000

  defmodule Data do
    @moduledoc """
    Data module stores the information for the state
    and persist it inside of the loop (the loop data).
    """
    @type t() :: %ExBank.Atm.Data{
            acc_no: nil | Account.acc_no(),
            pin: String.t(),
            digits: String.t(),
            interface: pid()
          }

    defstruct acc_no: nil,
              pin: "",
              digits: "",
              interface: nil
  end

  @spec start_link(pid()) :: :gen_statem.start_ret()
  @doc """
  Starts the state machine. A PID must be provided to know where to
  send async events (for the interface) when they are needed to be
  reported.
  """
  def start_link(interface) do
    GenStateMachine.start_link(__MODULE__, [interface])
  end

  @impl GenStateMachine
  @doc false
  def init([interface]) do
    Process.monitor(interface)
    {:ok, :idle, %Data{interface: interface}}
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
        actions = [{:reply, from, :ask_pin}, timeout()]
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

  def idle(:info, {:DOWN, _ref, :process, interface, reason}, %Data{interface: interface}) do
    {:stop, reason}
  end

  @doc """
  Implements the "get_pin" state.
  """
  def get_pin({:call, from}, {:digit, _}, %Data{digits: d}) when byte_size(d) >= 4 do
    actions = [{:reply, from, :no_more_digits}, timeout()]
    {:keep_state_and_data, actions}
  end

  def get_pin({:call, from}, {:digit, d}, data) do
    actions = [{:reply, from, :more_digits}, timeout()]
    data = %Data{data | digits: data.digits <> d}
    {:keep_state, data, actions}
  end

  def get_pin({:call, from}, :enter, data) do
    if Backend.pin_valid?(data.acc_no, data.digits) do
      data = %Data{data | digits: "", pin: data.digits}
      actions = [{:reply, from, :choose_option}, timeout()]
      {:next_state, :selection, data, actions}
    else
      actions = [{:reply, from, :invalid_pin}, timeout()]
      {:keep_state_and_data, actions}
    end
  end

  def get_pin({:call, from}, :clear, data) do
    data = %Data{data | digits: ""}
    actions = [{:reply, from, :ok}, timeout()]
    {:keep_state, data, actions}
  end

  def get_pin({:call, from}, :cancel, data) do
    data = %Data{data | digits: "", acc_no: nil}
    actions = [{:reply, from, :ok}]
    {:next_state, :idle, data, actions}
  end

  def get_pin({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def get_pin(:timeout, _time, data) do
    {:next_state, :timeout, data, [{:next_event, :internal, :timeout}]}
  end

  def get_pin({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}, timeout()]
    {:keep_state_and_data, actions}
  end

  def get_pin(:info, {:DOWN, _ref, :process, interface, reason}, %Data{interface: interface}) do
    {:stop, reason}
  end

  @doc """
  Implements "selection"
  """
  def selection({:call, from}, {:selection, :balance}, data) do
    {:ok, balance} = Backend.balance(data.acc_no, data.pin)
    actions = [{:reply, from, {:balance, balance}}, timeout()]
    {:keep_state_and_data, actions}
  end

  def selection({:call, from}, {:selection, :statement}, data) do
    {:ok, transactions} = Backend.transactions(data.acc_no, data.pin)
    actions = [{:reply, from, {:statement, transactions}}, timeout()]
    {:keep_state_and_data, actions}
  end

  def selection({:call, from}, {:selection, :withdraw}, data) do
    actions = [{:reply, from, :ask_amount}, timeout()]
    {:next_state, :withdraw, data, actions}
  end

  def selection({:call, from}, :cancel, data) do
    data = %Data{data | pin: "", acc_no: nil}
    actions = [{:reply, from, :ok}]
    {:next_state, :idle, data, actions}
  end

  def selection({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def selection(:timeout, _time, data) do
    {:next_state, :timeout, data, [{:next_event, :internal, :timeout}]}
  end

  def selection({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}, timeout()]
    {:keep_state_and_data, actions}
  end

  def selection(:info, {:DOWN, _ref, :process, interface, reason}, %Data{interface: interface}) do
    {:stop, reason}
  end

  @doc """
  Implements "withdraw".
  """
  def withdraw({:call, from}, {:digit, _}, %Data{digits: d}) when byte_size(d) >= 6 do
    actions = [{:reply, from, :no_more_digits}, timeout()]
    {:keep_state_and_data, actions}
  end

  def withdraw({:call, from}, {:digit, d}, data) do
    actions = [{:reply, from, :more_digits}, timeout()]
    data = %Data{data | digits: data.digits <> d}
    {:keep_state, data, actions}
  end

  def withdraw({:call, from}, :enter, data) do
    amount = String.to_integer(data.digits)

    case Backend.withdrawal(data.acc_no, data.pin, amount) do
      :ok ->
        actions = [{:reply, from, :success_withdraw}, timeout()]
        {:next_state, :selection, data, actions}

      {:error, :balance} ->
        actions = [{:reply, from, :no_balance}, timeout()]
        {:keep_state_and_data, actions}
    end
  end

  def withdraw({:call, from}, :clear, data) do
    data = %Data{data | digits: ""}
    actions = [{:reply, from, :ok}, timeout()]
    {:keep_state, data, actions}
  end

  def withdraw({:call, from}, :cancel, data) do
    data = %Data{data | acc_no: nil, digits: "", pin: ""}
    actions = [{:reply, from, :ok}]
    {:next_state, :idle, data, actions}
  end

  def withdraw({:call, from}, :stop, data) do
    replies = [{:reply, from, :ok}]
    {:stop_and_reply, :normal, replies, data}
  end

  def withdraw(:timeout, _time, data) do
    {:next_state, :timeout, data, [{:next_event, :internal, :timeout}]}
  end

  def withdraw({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}, timeout()]
    {:keep_state_and_data, actions}
  end

  def withdraw(:info, {:DOWN, _ref, :process, interface, reason}, %Data{interface: interface}) do
    {:stop, reason}
  end

  @doc """
  Implements timeout state.
  """
  def timeout(:internal, :timeout, %Data{interface: interface} = data) do
    GenServer.cast(interface, :timeout)
    {:next_state, :idle, %Data{data | acc_no: nil, pin: "", digits: ""}}
  end

  def timeout({:call, from}, _whatever, _data) do
    actions = [{:reply, from, :invalid_option}]
    {:keep_state_and_data, actions}
  end

  defp timeout() do
    Application.get_env(:ex_bank, :timeout, @default_timeout)
  end
end
