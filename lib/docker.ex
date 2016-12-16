defmodule Docker do
  use Application
  @moduledoc """
    This is the core Docker Application
  """

  def start do
    Application.ensure_all_started(:httpoison)
  end
end
