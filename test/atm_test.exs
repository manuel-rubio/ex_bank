defmodule ExBank.AtmTest do
  use ExUnit.Case, async: false

  alias ExBank.{Atm, Backend}

  setup do
    {:ok, _} = Backend.start_link()
    {:ok, atm} = Atm.start_link()
    %{atm: atm}
  end

  describe "idle:" do
    test "trying invalid card", %{atm: atm} do
      acc_no = 101
      assert :invalid_card = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "trying valid card", %{atm: atm} do
      acc_no = 100
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "trying invalid requests", %{atm: atm} do
      assert :invalid_option = GenStateMachine.call(atm, {:digits, "1"})
      assert :invalid_option = GenStateMachine.call(atm, :enter)
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :balance})
      assert :invalid_option = GenStateMachine.call(atm, :clear)
      assert :invalid_option = GenStateMachine.call(atm, :cancel)
    end

    test "stopping", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :stop)
      refute Process.alive?(atm)
    end
  end

  describe "get_pin:" do
    setup %{atm: atm} do
      acc_no = 100
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
      :ok
    end

    test "trying more digits than granted", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :no_more_digits = GenStateMachine.call(atm, {:digit, "1"})
    end

    test "trying digits and clear to put correct ones", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :ok = GenStateMachine.call(atm, :clear)
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "2"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "3"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "4"})
      assert :ok = GenStateMachine.call(atm, :clear)
    end

    test "trying invalid pin", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :invalid_pin = GenStateMachine.call(atm, :enter)
    end

    test "cancel to choose another card", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :cancel)

      acc_no = 200
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "using a correct pin", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "2"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "3"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "4"})
      assert :choose_option = GenStateMachine.call(atm, :enter)
    end

    test "tyring change card", %{atm: atm} do
      acc_no = 200
      assert :invalid_option = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "trying invalid requests", %{atm: atm} do
      assert :invalid_pin = GenStateMachine.call(atm, :enter)
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :balance})
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :statement})
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :withdraw})
    end

    test "cancelling", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :cancel)

      acc_no = 200
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "stopping", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :stop)
      refute Process.alive?(atm)
    end
  end

  describe "selection:" do
    setup %{atm: atm} do
      acc_no = 100
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "2"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "3"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "4"})
      assert :choose_option = GenStateMachine.call(atm, :enter)
      :ok
    end

    test "getting the balance", %{atm: atm} do
      assert {:balance, 100} = GenStateMachine.call(atm, {:selection, :balance})
    end

    test "getting the statement", %{atm: atm} do
      assert {:statement, [{:credit, _timestamp, 100}]} =
               GenStateMachine.call(atm, {:selection, :statement})
    end

    test "going to withdraw", %{atm: atm} do
      assert :ask_amount = GenStateMachine.call(atm, {:selection, :withdraw})
    end

    test "trying invalid requests", %{atm: atm} do
      assert :invalid_option = GenStateMachine.call(atm, {:digits, "1"})
      assert :invalid_option = GenStateMachine.call(atm, :enter)
      assert :invalid_option = GenStateMachine.call(atm, :clear)
    end

    test "cancelling", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :cancel)

      acc_no = 200
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "stopping", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :stop)
      refute Process.alive?(atm)
    end
  end

  describe "withdraw:" do
    setup %{atm: atm} do
      acc_no = 100
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "2"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "3"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "4"})
      assert :choose_option = GenStateMachine.call(atm, :enter)
      assert :ask_amount = GenStateMachine.call(atm, {:selection, :withdraw})
      :ok
    end

    test "trying more digits than granted", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :no_more_digits = GenStateMachine.call(atm, {:digit, "1"})
    end

    test "trying digits and clear to put correct ones", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :ok = GenStateMachine.call(atm, :clear)
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "2"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "3"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "4"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "5"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "6"})
      assert :ok = GenStateMachine.call(atm, :clear)
    end

    test "retrieving 10", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "0"})
      assert :success_withdraw = GenStateMachine.call(atm, :enter)

      assert {:balance, 90} = GenStateMachine.call(atm, {:selection, :balance})
    end

    test "retrieving everything", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "1"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "0"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "0"})
      assert :success_withdraw = GenStateMachine.call(atm, :enter)

      assert {:balance, 0} = GenStateMachine.call(atm, {:selection, :balance})
    end

    test "trying retrieve 500", %{atm: atm} do
      assert :more_digits = GenStateMachine.call(atm, {:digit, "5"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "0"})
      assert :more_digits = GenStateMachine.call(atm, {:digit, "0"})
      assert :no_balance = GenStateMachine.call(atm, :enter)
    end

    test "trying invalid requests", %{atm: atm} do
      assert :invalid_option = GenStateMachine.call(atm, {:card_inserted, 100})
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :balance})
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :statement})
      assert :invalid_option = GenStateMachine.call(atm, {:selection, :withdraw})
    end

    test "cancelling", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :cancel)

      acc_no = 200
      assert :ask_pin = GenStateMachine.call(atm, {:card_inserted, acc_no})
    end

    test "stopping", %{atm: atm} do
      assert :ok = GenStateMachine.call(atm, :stop)
      refute Process.alive?(atm)
    end
  end
end
