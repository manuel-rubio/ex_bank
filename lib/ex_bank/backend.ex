defmodule ExBank.Backend do
  @moduledoc """
  Backend implements the protocol agreed with the fronted team.
  """

  use GenServer

  alias ExBank.{Account, BackendDb}

  @server {:global, :backend}

  @doc """
  Start the generic server, register it locally with the name of the module.
  For now we will not do anything with the argument passed in, but we need
  it for later.
  """
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @server)
  end

  @doc """
  Stop the server.
  """
  def stop() do
    GenServer.stop(@server)
  end

  defp call(msg), do: GenServer.call(@server, msg)
  defp cast(msg), do: GenServer.cast(@server, msg)

  @type account() :: {
          :account,
          Account.acc_no(),
          Account.pin(),
          Account.name(),
          Account.amount(),
          Account.transactions()
        }

  @spec get(Account.acc_no()) :: account() | {:error, :no_account}
  @doc """
  Return the account information specified by the account number. In case
  the account does not exist, return the tuple {:error, :no_account}.
  """
  def get(acc_no), do: call({:get, acc_no})

  @spec get_by_name(Account.name()) :: [account()]
  @doc """
  Return all the accounts belonging to the name specified.
  """
  def get_by_name(name), do: call({:get_by_name, name})

  @spec new_account(Account.acc_no(), Account.pin(), Account.name()) ::
          :ok | {:error, :exists}
  @doc """
  Create a new account passing the account number, pin and name as parameters.
  """
  def new_account(acc_no, pin, name), do: cast({:new_account, acc_no, pin, name})

  @spec list() :: [account()]
  @doc """
  Return the list of all accounts.
  """
  def list(), do: call(:list)

  @spec pin_valid?(Account.acc_no(), Account.pin()) :: boolean()
  @doc """
  Return true or false depending on whether the PIN is valid for the account.
  """
  def pin_valid?(acc_no, pin), do: call({:pin_valid, acc_no, pin})

  @spec withdrawal(Account.acc_no(), Account.pin(), Account.amount()) ::
          :ok | {:error, :balance} | {:error, :forbidden}
  @doc """
  Debit the account with the amount specified in the third parameter. This
  operation is only permitted if the PIN is valid. If there is not enough money
  on the account, then return the tuple {:error, :balance}
  """
  def withdrawal(acc_no, pin, amount), do: call({:withdrawal, acc_no, pin, amount})

  @spec deposit(Account.acc_no(), Account.pin(), Account.amount()) ::
          :ok | {:error, :forbidden}
  @doc """
  Credit the account with the amount specified in the second parameter. Since
  we don’t need to deal with money laundering regulations, this is always
  allowed.
  """
  def deposit(acc_no, pin, amount), do: call({:deposit, acc_no, pin, amount})

  @spec transfer(Account.acc_no(), Account.acc_no(), Account.amount(), Account.pin()) ::
          :ok | {:error, :balance} | {:error, :forbidden} | {:error, :no_account}
  @doc """
  Transfer the amount specified in the third parameter from the account in the
  first parameter to the account in the second parameter. This operation is
  only allowed if the PIN (fourth parameter) is valid for the “from” account.
  Transferring money is the same as debiting the “from” account and crediting
  the “to” account.
  """
  def transfer(acc_no1, acc_no2, amount, pin) do
    call({:transfer, acc_no1, acc_no2, amount, pin})
  end

  @spec balance(Account.acc_no(), Account.pin()) ::
          {:ok, Account.amount()} | {:error, :forbidden}
  @doc """
  Return the current balance for the account number given in the first
  parameter. This operation is only allowed if the PIN (second parameter) is
  valid for the account.
  """
  def balance(acc_no, pin), do: call({:balance, acc_no, pin})

  @spec transactions(Account.acc_no(), Account.pin()) ::
          {:ok, Account.transactions()} | {:error, :forbidden}
  @doc """
  Return the list of transactions.
  """
  def transactions(acc_no, pin), do: call({:transactions, acc_no, pin})

  @spec block(Account.acc_no()) :: :ok
  @doc """
  Blocks an account.
  """
  def block(acc_no), do: cast({:block, acc_no})

  @spec unblock(Account.acc_no()) :: :ok
  @doc """
  Unblocks an account.
  """
  def unblock(acc_no), do: cast({:unblock, acc_no})

  defp to_tuple(tuple) when is_tuple(tuple), do: tuple
  defp to_tuple([]), do: []
  defp to_tuple([%Account{} | _] = acc), do: Enum.map(acc, &to_tuple/1)

  defp to_tuple(%Account{} = acc) do
    {:account, acc.acc_no, acc.pin, acc.name, acc.balance, acc.transactions}
  end

  defp to_tuple(other), do: raise(ArgumentError, message: other)

  @doc false
  @impl GenServer
  def init([]) do
    db_ref = BackendDb.create_db()

    for {acc_no, name, pin, balance} <- Application.get_env(:ex_bank, :demo_data) do
      BackendDb.new_account(db_ref, acc_no, pin, name)
      BackendDb.credit(db_ref, acc_no, balance)
    end

    {:ok, db_ref}
  end

  @impl GenServer
  def handle_cast({:new_account, acc_no, pin, name}, db_ref) do
    BackendDb.new_account(db_ref, acc_no, pin, name)
    {:noreply, db_ref}
  end

  @impl GenServer
  def handle_call({:get, acc_no}, _from, db_ref) do
    case BackendDb.lookup(db_ref, acc_no) do
      {:error, :instance} -> {:reply, {:error, :no_account}, db_ref}
      %Account{} = acc -> {:reply, to_tuple(acc), db_ref}
    end
  end

  def handle_call({:get_by_name, name}, _from, db_ref) do
    {:reply, to_tuple(BackendDb.lookup_by_name(db_ref, name)), db_ref}
  end

  def handle_call(:list, _from, db_ref) do
    {:reply, to_tuple(BackendDb.all_accounts(db_ref)), db_ref}
  end

  def handle_call({:pin_valid, acc_no, pin}, _from, db_ref) do
    {:reply, BackendDb.is_pin_valid?(db_ref, acc_no, pin), db_ref}
  end

  def handle_call({:withdrawal, acc_no, pin, amount}, _from, db_ref) do
    if BackendDb.is_pin_valid?(db_ref, acc_no, pin) do
      case BackendDb.debit(db_ref, acc_no, amount) do
        ^db_ref -> {:reply, :ok, db_ref}
        error -> {:reply, error, db_ref}
      end
    else
      {:reply, {:error, :forbidden}, db_ref}
    end
  end

  def handle_call({:deposit, acc_no, pin, amount}, _from, db_ref) do
    if BackendDb.is_pin_valid?(db_ref, acc_no, pin) do
      case BackendDb.credit(db_ref, acc_no, amount) do
        ^db_ref -> {:reply, :ok, db_ref}
        error -> {:reply, error, db_ref}
      end
    else
      {:reply, {:error, :forbidden}, db_ref}
    end
  end

  def handle_call({:transfer, acc_no1, acc_no2, pin, amount}, _from, db_ref) do
    case {
      BackendDb.is_pin_valid?(db_ref, acc_no1, pin),
      BackendDb.lookup(db_ref, acc_no2)
    } do
      {true, %Account{}} ->
        case BackendDb.debit(db_ref, acc_no1, amount) do
          ^db_ref ->
            ^db_ref = BackendDb.credit(db_ref, acc_no2, amount)
            {:reply, :ok, db_ref}

          {:error, _} = error ->
            {:reply, error, db_ref}
        end

      {false, _} ->
        {:reply, {:error, :forbidden}, db_ref}

      {true, {:error, :instance}} ->
        {:reply, {:error, :no_account}, db_ref}
    end
  end

  def handle_call({:balance, acc_no, pin}, _from, db_ref) do
    if BackendDb.is_pin_valid?(db_ref, acc_no, pin) do
      {:reply, {:ok, BackendDb.lookup(db_ref, acc_no).balance}, db_ref}
    else
      {:reply, {:error, :forbidden}, db_ref}
    end
  end

  def handle_call({:transactions, acc_no, pin}, _from, db_ref) do
    if BackendDb.is_pin_valid?(db_ref, acc_no, pin) do
      {:reply, {:ok, BackendDb.lookup(db_ref, acc_no).transactions}, db_ref}
    else
      {:reply, {:error, :forbidden}, db_ref}
    end
  end
end
