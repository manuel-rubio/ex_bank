defmodule ExBank.BackendTest do
  use ExUnit.Case, async: false

  alias ExBank.Backend

  test "starting/stopping the server" do
    assert {:ok, _} = Backend.start_link()
    assert is_pid(:global.whereis_name(:backend))
    assert :ok == Backend.stop()
    assert :undefined == :global.whereis_name(:backend)
  end

  describe "get account" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
    end

    test "sucessfully" do
      assert {:account, 1, "1234", "ESL", 0, []} == Backend.get(1)
    end

    test "unsucessfully" do
      assert {:error, :no_account} == Backend.get(2)
    end

    test "sucessfully with name" do
      assert [{:account, 1, "1234", "ESL", 0, []}] == Backend.get_by_name("ESL")
    end

    test "unsucessfully with name" do
      assert [] == Backend.get_by_name("NoESL")
    end
  end

  describe "list" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
      :ok = Backend.new_account(_acc_no = 2, _pin = "2345", _name = "Plataformatec")
      :ok = Backend.new_account(_acc_no = 3, _pin = "3456", _name = "Dashbit")
    end

    test "sucessfully" do
      assert [
               {:account, 1, "1234", "ESL", 0, []},
               {:account, 2, "2345", "Plataformatec", 0, []},
               {:account, 3, "3456", "Dashbit", 0, []}
             ] == Enum.sort(Backend.list())
    end
  end

  describe "pin" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
    end

    test "sucessfully" do
      assert Backend.pin_valid?(1, "1234")
    end

    test "unsucessfully" do
      refute Backend.pin_valid?(1, "1235")
    end
  end

  describe "withdrawal" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
      :ok = Backend.deposit(1, "1234", 100)
    end

    test "sucessfully" do
      assert :ok == Backend.withdrawal(1, "1234", 50)
      assert {:ok, 50} == Backend.balance(1, "1234")
    end

    test "unsucessfully (no balance)" do
      assert {:error, :balance} == Backend.withdrawal(1, "1234", 150)
      assert {:ok, 100} == Backend.balance(1, "1234")
    end

    test "unsucessfully (forbidden)" do
      assert {:error, :forbidden} == Backend.withdrawal(8, "1234", 50)
      assert {:ok, 100} == Backend.balance(1, "1234")
    end
  end

  describe "deposit" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
    end

    test "sucessfully" do
      assert :ok == Backend.deposit(1, "1234", 50)
      assert {:ok, 50} == Backend.balance(1, "1234")

      assert :ok == Backend.deposit(1, "1234", 50)
      assert {:ok, 100} == Backend.balance(1, "1234")
    end

    test "unsucessfully (forbidden)" do
      assert {:error, :forbidden} == Backend.deposit(42, "1234", 50)
    end
  end

  describe "transfer" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
      :ok = Backend.new_account(_acc_no = 3, _pin = "4321", _name = "Dashbit")
      :ok = Backend.deposit(1, "1234", 100)
    end

    test "sucessfully" do
      assert :ok == Backend.transfer(1, 3, "1234", 100)
      assert {:ok, 0} == Backend.balance(1, "1234")
      assert {:ok, 100} == Backend.balance(3, "4321")
    end

    test "unsucessfully (no balance)" do
      assert {:error, :balance} == Backend.transfer(1, 3, "1234", 500)
    end

    test "unsucessfully (forbidden)" do
      assert {:error, :forbidden} == Backend.transfer(1, 3, "1111", 100)
    end

    test "unsucessfully (no_account)" do
      assert {:error, :no_account} == Backend.transfer(1, 2, "1234", 100)
    end
  end

  describe "balance" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
      :ok = Backend.deposit(1, "1234", 100)
    end

    test "sucessfully" do
      assert {:ok, 100} == Backend.balance(1, "1234")
    end

    test "unsucessfully (forbidden)" do
      assert {:error, :forbidden} == Backend.balance(5, "1234")
    end
  end

  describe "transactions" do
    setup do
      {:ok, _} = Backend.start_link()
      :ok = Backend.new_account(_acc_no = 1, _pin = "1234", _name = "ESL")
      :ok = Backend.deposit(1, "1234", 100)
      :ok = Backend.withdrawal(1, "1234", 50)
      :ok = Backend.deposit(1, "1234", 25)
    end

    test "sucessfully" do
      assert {:ok,
              [
                {:credit, _, 25},
                {:debit, _, 50},
                {:credit, _, 100}
              ]} = Backend.transactions(1, "1234")
    end

    test "unsucessfully (forbidden)" do
      assert {:error, :forbidden} == Backend.transactions(5, "1234")
    end
  end
end
