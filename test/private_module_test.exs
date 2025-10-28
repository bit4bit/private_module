defmodule PrivateModuleTest do
  use ExUnit.Case, async: false
  require TestProject

  test "compile test project" do
    TestProject.setup(:test1)

    TestProject.insert_code(:test1, """
    defmodule Demo do
      def hello do
      end
    end
    """)

    assert TestProject.compile(:test1) == :ok
  end

  test "module not allowed to call private module" do
    TestProject.setup(:test2)

    TestProject.insert_code(:test2, """
    defmodule DemoNotAllowed do
      def hello do
        Demo.Private.hello()
      end
    end

    defmodule Demo.Private do
      use PrivateModule
      def hello do
        :hello
      end
    end
    """)

    {:error, error} = TestProject.compile(:test2)

    assert error =~
             ~r/Module Elixir.DemoNotAllowed is not allowed to call private module Elixir.Demo.Private/
  end

  test "module allowed to call private module" do
    TestProject.setup(:test3)

    TestProject.insert_code(:test3, """
    defmodule Demo do
      def hello do
        Demo.Private.hello()
      end
    end

    defmodule Demo.Private do
      use PrivateModule
      def hello do
        :hello
      end
    end
    """)

    assert TestProject.compile(:test3) == :ok
  end
end
