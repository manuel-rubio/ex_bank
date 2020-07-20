defmodule ExBank.Account do
  @moduledoc """
  Account is responsible to handle the information regarding the
  struct with the same name. Try to use as much as possible the
  API defined in this module instead of access directly to the
  information of the struct.
  """
  alias ExBank.Account

  @type acc_no :: non_neg_integer()
  @type pin() :: String.t()
  @type name() :: String.t()
  @type amount() :: non_neg_integer()
  @type transaction_type() :: :credit | :debit
  @type block() :: boolean()

  @type transaction() :: {
          transaction_type(),
          DateTime.t(),
          amount()
        }
  @type transactions() :: [transaction()]

  @type t() :: %ExBank.Account{
          acc_no: acc_no(),
          pin: pin(),
          name: name(),
          balance: amount(),
          transactions: transactions(),
          blocked: boolean()
        }

  defstruct [
    :acc_no,
    :pin,
    :name,
    balance: 0,
    transactions: []
  ]

  @spec new(acc_no(), pin(), name()) :: t()
  def new(acc_no, pin, name) do
    %Account{acc_no: acc_no, pin: pin, name: name}
  end

  @spec increase_balance(t(), amount()) :: t()
  def increase_balance(
        %Account{balance: balance, transactions: transactions} = acc,
        amount
      ) do
    balance = balance + amount
    transactions = [{:credit, DateTime.utc_now(), amount} | transactions]
    %Account{acc | balance: balance, transactions: transactions}
  end

  @spec decrease_balance(t(), amount()) :: t() | {:error, :balance}
  def decrease_balance(
        %Account{balance: balance, transactions: transactions} = acc,
        amount
      )
      when balance >= amount do
    balance = balance - amount
    transactions = [{:debit, DateTime.utc_now(), amount} | transactions]
    %Account{acc | balance: balance, transactions: transactions}
  end

  def decrease_balance(%Account{}, _amount), do: {:error, :balance}

  @spec get_balance(t()) :: amount()
  def get_balance(%Account{balance: balance}), do: balance

  @spec is_pin_valid?(t(), pin()) :: boolean()
  def is_pin_valid?(%Account{pin: pin}, pin), do: true
  def is_pin_valid?(%Account{}, _pin), do: false

  defimpl String.Chars, for: Account do
    alias ExBank.Account

    def to_string(%Account{acc_no: acc_no, name: name, balance: balance}) do
      "Account ##{acc_no}: #{name}; Balance: #{balance}"
    end
  end
end
