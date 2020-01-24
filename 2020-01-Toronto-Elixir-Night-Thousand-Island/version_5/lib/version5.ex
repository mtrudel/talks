defmodule Version5 do
  @moduledoc """
  Documentation for Version5.
  """

  def shutdown do
    Supervisor.stop(Version5.Supervisor)
  end
end
