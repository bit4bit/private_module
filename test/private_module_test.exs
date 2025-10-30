defmodule PrivateModuleTest do
  use ExUnit.Case, async: false
  require TestProject

  test "compile test project" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo do
        def hello do
        end
      end
      """
    end)

    assert TestProject.compile(test_project) == :ok
  end

  test "module not allowed to call private module using cli --warnings-as-errors" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.DemoNotAllowed do
        def hello do
          #{ns}.Demo.Private.hello()
        end
      end

      defmodule #{ns}.Demo.Private do
        use PrivateModule
        def hello do
          :hello
        end
      end
      """
    end)

    {:error, error} = TestProject.compile(test_project, ["--warnings-as-errors"])

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.Private/
  end

  test "module not allowed to call private module using elixirc_options" do
    test_project = TestProject.setup(project: [elixirc_options: [warnings_as_errors: true]])

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.DemoNotAllowed do
        def hello do
          #{ns}.Demo.Private.hello()
        end
      end

      defmodule #{ns}.Demo.Private do
        use PrivateModule
        def hello do
          :hello
        end
      end
      """
    end)

    {:error, error} = TestProject.compile(test_project)

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.Private/
  end

  test "module not allowed to alias private module" do
    test_project = TestProject.setup(project: [elixirc_options: [warnings_as_errors: true]])

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo.Private do
        use PrivateModule
      end

      defmodule #{ns}.DemoNotAllowed do
        alias #{ns}.Demo.Private
        Private
      end

      """
    end)

    {:error, error} = TestProject.compile(test_project)

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.Private/
  end

  test "module not allowed to require private module" do
    test_project = TestProject.setup(project: [elixirc_options: [warnings_as_errors: true]])

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo.Private do
        use PrivateModule
      end

      defmodule #{ns}.DemoNotAllowed do
        require #{ns}.Demo.Private
        Private
      end

      """
    end)

    {:error, error} = TestProject.compile(test_project)

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.Private/
  end

  test "module not allowed to use private module" do
    test_project = TestProject.setup(project: [elixirc_options: [warnings_as_errors: true]])

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo.Private do
        use PrivateModule

        defmacro __using__(_opts) do
          quote do
          end
        end
      end

      defmodule #{ns}.DemoNotAllowed do
        use #{ns}.Demo.Private
        Private
      end

      """
    end)

    {:error, error} = TestProject.compile(test_project)

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.Private/
  end

  test "module not allowed to use private structure" do
    test_project = TestProject.setup(project: [elixirc_options: [warnings_as_errors: true]])

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo.PrivateStructure do
        use PrivateModule

        defstruct [:hello]
      end

      defmodule #{ns}.DemoNotAllowed do
        def hello do
          %#{ns}.Demo.PrivateStructure{}
        end
      end

      defmodule #{ns}.DemoNotAllowedAlias do
        alias #{ns}.Demo.PrivateStructure

        def hello do
          %PrivateStructure{}
        end
      end
      """
    end)

    {:error, error} = TestProject.compile(test_project)

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.PrivateStructure/

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowedAlias is not allowed to use private module Elixir.#{TestProject.ns(test_project)}.Demo.PrivateStructure/
  end

  test "module allowed to use private structure" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo.PrivateStructure do
        use PrivateModule
        defstruct [:hello]
      end

      defmodule #{ns}.Demo do
        def hello do
          %#{ns}.Demo.PrivateStructure{}
        end
      end
      """
    end)

    assert TestProject.compile(test_project, ["--warnings-as-errors"]) == :ok
  end

  test "module allowed to call private module" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo do
        def hello do
          #{ns}.Demo.Private.hello()
        end
      end

      defmodule #{ns}.Demo.Private do
        use PrivateModule
        def hello do
          :hello
        end
      end
      """
    end)

    assert TestProject.compile(test_project, ["--warnings-as-errors"]) == :ok
  end

  test "transitive module allowed to call private module" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo do
        def hello do
          #{ns}.Demo.Secret.hello()
        end
      end

      defmodule #{ns}.Demo.Secret do
        use PrivateModule
        def hello do
          :hello
        end
      end

      defmodule #{ns}.DemoTransative do
        def hello do
          #{ns}.Demo.hello()
        end
      end
      """
    end)

    assert TestProject.compile(test_project, ["--warnings-as-errors"]) == :ok
  end

  test "transitive module allowed to use private structure" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo.SecretStruct do
        use PrivateModule
        defstruct [:name]
      end

      defmodule #{ns}.Demo do
        def hello do
          %#{ns}.Demo.SecretStruct{name: "John"}
        end
      end


      defmodule #{ns}.DemoTransative do
        def hello do
          #{ns}.Demo.hello()
        end
      end
      """
    end)

    assert TestProject.compile(test_project, ["--warnings-as-errors"]) == :ok
  end

  test "module allowed to call private module specify module" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.DemoTitan do
        def hello do
          #{ns}.Demo.Private.hello()
        end
      end

      defmodule #{ns}.Demo.Private do
        # use with caution
        use PrivateModule, for: [#{ns}.DemoTitan]
        def hello do
          :hello
        end
      end
      """
    end)

    assert TestProject.compile(test_project, ["--warnings-as-errors"]) == :ok
  end
end
