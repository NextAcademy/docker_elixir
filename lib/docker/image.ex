defmodule Docker.Image do
  alias Docker.Client
  alias Docker.Client.Response

  def all(host, opts \\ %{}) do
    "#{host}/images/json"
    |> Client.add_query_params(opts)
    |> Client.send_request(:get)
    |> Response.parse(:all)
  end

  def list(host, opts \\ %{}) do
    case all(host, opts) do
      {:ok, results} -> Enum.map(results, &(&1["RepoTags"] |> hd))
      {:error, reason} -> {:error, reason}
    end
  end
end
