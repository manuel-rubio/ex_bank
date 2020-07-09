defmodule ExBank.BackendDbTest do
  use ExUnit.Case, async: false
  alias ExBank.BackendDb

  doctest BackendDb

  describe "create_db" do
    test "correctly" do
      db_ref = BackendDb.create_db()
      assert is_atom(db_ref)

      BackendDb.close(db_ref)
    end

    test "double creation error" do
      db_ref = BackendDb.create_db()
      assert is_atom(db_ref)

      assert_raise ArgumentError, &BackendDb.create_db/0
      BackendDb.close(db_ref)
    end
  end

  describe "lookup" do
    setup do
      db_ref = BackendDb.create_db()
      %{db_ref: db_ref}
    end

    test "for an existent value", %{db_ref: db_ref} do
      result =
        db_ref
        |> BackendDb.new_account(1, "1234", "ESL")
        |> BackendDb.credit(1, 100)
        |> BackendDb.lookup(1)
        |> Map.take([:acc_no, :name, :balance])

      assert %{acc_no: 1, balance: 100, name: "ESL"} == result
    end

    test "for an inexistent value", %{db_ref: db_ref} do
      assert {:error, :instance} == BackendDb.lookup(db_ref, 2)
    end
  end

  describe "lookup_by_name" do
    setup do
      db_ref = BackendDb.create_db()
      %{db_ref: db_ref}
    end

    test "for an existent value", %{db_ref: db_ref} do
      result =
        db_ref
        |> BackendDb.new_account(1, "1234", "ESL")
        |> BackendDb.credit(1, 100)
        |> BackendDb.lookup_by_name("ESL")
        |> Enum.map(&Map.take(&1, [:acc_no, :name, :balance]))

      assert [%{acc_no: 1, balance: 100, name: "ESL"}] == result
    end

    test "for an inexistent value", %{db_ref: db_ref} do
      assert {:error, :instance} == BackendDb.lookup(db_ref, 2)
    end
  end

  describe "create_account" do
    setup do
      db_ref = BackendDb.create_db()
      %{db_ref: db_ref}
    end

    test "successfully", %{db_ref: db_ref} do
      assert db_ref == BackendDb.new_account(db_ref, 1, "1234", "ESL")
    end

    test "already existent", %{db_ref: db_ref} do
      assert db_ref == BackendDb.new_account(db_ref, 1, "1234", "ESL")
      assert {:error, :exists} == BackendDb.new_account(db_ref, 1, "1234", "ESL")
    end
  end

  describe "credit" do
    setup do
      account = 1

      db_ref =
        BackendDb.create_db()
        |> BackendDb.new_account(account, "1234", "ESL")

      %{db_ref: db_ref, account: account}
    end

    test "adding to an account successfully", %{db_ref: db_ref, account: account} do
      assert db_ref == BackendDb.credit(db_ref, account, 100)
      assert 100 == BackendDb.lookup(db_ref, account).balance

      assert db_ref == BackendDb.credit(db_ref, account, 50)
      assert 150 == BackendDb.lookup(db_ref, account).balance
    end
  end

  describe "debit" do
    setup do
      account = 1

      db_ref =
        BackendDb.create_db()
        |> BackendDb.new_account(account, "1234", "ESL")
        |> BackendDb.credit(account, 100)

      %{db_ref: db_ref, account: account}
    end

    test "subtracting from an account successfully", %{db_ref: db_ref, account: account} do
      assert db_ref == BackendDb.debit(db_ref, account, 25)
      assert 75 == BackendDb.lookup(db_ref, account).balance

      assert db_ref == BackendDb.debit(db_ref, account, 75)
      assert 0 == BackendDb.lookup(db_ref, account).balance
    end

    test "subtracting from an account unsuccessfully", %{db_ref: db_ref, account: account} do
      assert {:error, _} = BackendDb.debit(db_ref, account, 150)
    end
  end

  describe "pin" do
    setup do
      account = 1

      db_ref =
        BackendDb.create_db()
        |> BackendDb.new_account(account, "1234", "ESL")

      %{db_ref: db_ref, account: account}
    end

    test "checking valid", %{db_ref: db_ref, account: account} do
      assert BackendDb.is_pin_valid?(db_ref, account, "1234")
    end

    test "checking invalid", %{db_ref: db_ref, account: account} do
      refute BackendDb.is_pin_valid?(db_ref, account, "4321")
    end
  end

  describe "close" do
    setup do
      db_ref = BackendDb.create_db()
      %{db_ref: db_ref}
    end

    test "account sucessfully", %{db_ref: db_ref} do
      assert :ok == BackendDb.close(db_ref)

      assert_raise ArgumentError, fn -> BackendDb.new_account(db_ref, 1, "1234", "ESL") end
    end
  end
end
