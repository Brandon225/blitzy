defmodule Blitzy do
  @moduledoc """
  Documentation for Blitzy.
  """

  use Application

  def start(_type, _args) do
    Blitzy.Supervisor.start_link(:ok)
  end

end

