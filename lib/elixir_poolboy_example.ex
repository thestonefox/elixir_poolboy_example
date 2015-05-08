defmodule ElixirPoolboyExample do
  use Application

  def start(_type, _args) do
    children = []

    options = [
      strategy: :one_for_one,
      name: ElixirPoolboyExample.Supervisor
    ]

    Supervisor.start_link(children, options)
  end
end
