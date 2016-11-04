defmodule Docker.ClientTest do
  use ExUnit.Case
  doctest Docker.Client
  @host "localhost:2375"

  test "able to parse json response body" do
    url = @host <> "/containers/json"
    assert Docker.Client.get(url) == {:ok, [_]}
  end
end
