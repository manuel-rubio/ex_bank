defmodule ExBank.BackendDb do
  alias ExBank.Account

  @type db_ref() :: :ets.tid()

  @spec create_db() :: db_ref()
  @doc """
  Create a named ETS table called :accounts and configure it to be of the type
  :set. The function should return the ETS table name.
  """
  def create_db() do
    {:error, :noimpl}
  end

  @spec lookup(db_ref(), Account.acc_no()) :: Account.t() | {:error, :instance}
  @doc """
  Return an account based on the account number. If no such account is present,
  return the tuple {:error, :instance}. The first parameter is the account number
  (an integer), the second parameter is the table name.

  Examples:
      iex> alias ExBank.BackendDb
      iex> BackendDb.create_db()
      iex> |> BackendDb.new_account(1, "1234", "ESL")
      iex> |> BackendDb.credit(1, 100)
      iex> |> BackendDb.lookup(1)
      iex> |> Map.take([:acc_no, :name, :balance])
      %{acc_no: 1, balance: 100, name: "ESL"}
  """
  def lookup(db_ref, acc_no) do
    {:error, :noimpl}
  end

  @spec lookup_by_name(db_ref(), Account.name()) :: [Account.t()]
  @doc """
  Return the list of accounts belonging to the same person. If no such account is
  present, return an empty list. The first parameter is the account holder’s name
  (a string), the second parameter is the table name.

  Examples:
      iex> alias ExBank.BackendDb
      iex> BackendDb.create_db()
      iex> |> BackendDb.new_account(1, "1234", "ESL")
      iex> |> BackendDb.credit(1, 100)
      iex> |> BackendDb.lookup_by_name("ESL")
      iex> |> Enum.map(&Map.take(&1, [:acc_no, :name, :balance]))
      [%{acc_no: 1, balance: 100, name: "ESL"}]
  """
  def lookup_by_name(db_ref, name) do
    #  Hint: Use :ets.match/2.
    {:error, :noimpl}
  end

  @spec new_account(db_ref(), Account.acc_no(), Account.pin(), Account.name()) ::
          db_ref() | {:error, :exists}
  @doc """
  Return again the db_ref after creating a new account. If the account number
  already exists, return the tuple {:error, :exists}. The first parameter is
  the account number, the second parameter is the PIN (a string), the third
  parameter is the name of the account holder, and the fourth parameter is
  the table name.
  """
  def new_account(db_ref, acc_no, pin, name) do
    {:error, :noimpl}
  end

  @spec credit(db_ref(), Account.acc_no(), Account.amount()) :: db_ref() | {:error, :instance}
  @doc """
  Increase the balance of the account specified by the first parameter by the
  amount (integer) specified by the second parameter. Once the balance is
  updated, add a transaction log entry to the list of the following form in
  {:credit, date_time, amount}, where you can use DateTime.utc_now/0 to get a
  well structured time representation. If the account specified by the account
  number is not found, then return the tuple {:error, :instance}. The last
  parameter is the table name.
  """
  def credit(db_ref, acc_no, amount) do
    {:error, :noimpl}
  end

  @spec debit(db_ref(), Account.acc_no(), Account.amount()) ::
          db_ref() | {:error, :instance} | {:error, String.t()}
  @doc """
  Decrease the balance of the account number by the amount (integer).
  Once the balance is updated, add a transaction log of the format
  {:debit, date_time, amount} to the head of the list stored in the
  transactions field. Use DateTime.utc_now/0. Only decrease the balance
  if the amount is not greater than the balance, returning the tuple
  {:error, :balance} when it is not enough. If the account specified by the
  account number is not found, return {:error, :instance}. The last parameter
  is the table name.
  """
  def debit(db_ref, acc_no, amount) do
    {:error, :noimpl}
  end

  @spec is_pin_valid?(db_ref(), Account.acc_no(), Account.pin()) :: boolean()
  @doc """
  Validate that the PIN is the same as the PIN stored in the account specified
  by the account number. If it is the same, return true, else false. The last
  parameter is the table name.

  Examples:
      iex> alias ExBank.BackendDb
      iex> BackendDb.create_db()
      iex> |> BackendDb.new_account(1, "1234", "ESL")
      iex> |> BackendDb.is_pin_valid?(1, "1234")
      true

      iex> alias ExBank.BackendDb
      iex> BackendDb.create_db()
      iex> |> BackendDb.new_account(1, "1234", "ESL")
      iex> |> BackendDb.is_pin_valid?(1, "4321")
      false
  """
  def is_pin_valid?(db_ref, acc_no, pin) do
    {:error, :noimpl}
  end

  @spec all_accounts(db_ref()) :: [Account.t()]
  @doc """
  Return all the accounts in a list stored in the table specified by the
  parameter.
  """
  def all_accounts(db_ref) do
    # Hint: Use :ets.tab2list/1.
    {:error, :noimpl}
  end

  @spec close(db_ref()) :: :ok
  @doc """
  Delete the ETS table specified by the parameter.
  """
  def close(db_ref) do
    {:error, :noimpl}
  end
end
