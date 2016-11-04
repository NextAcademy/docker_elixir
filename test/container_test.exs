defmodule Docker.ContainerTest do
  use ExUnit.Case
  doctest Docker.Container
  @host "localhost:2375"

  test "able to get list of all containers" do
    assert Docker.Container.all(@host) == [_] 
  end
end
