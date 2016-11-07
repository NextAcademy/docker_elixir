defmodule Docker.Client do
  use HTTPoison.Base

  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, json} -> json
      _ -> body
    end
  end

  def post_json!(url, body \\ %{}, opts \\ []) do
    post!( url, Poison.encode!(body), 
          %{"Content-Type"=>"application/json"},
          opts
        )
  end

  def add_query_params(url, params) do
    "#{url}?#{URI.encode_query(params)}"
  end
end

