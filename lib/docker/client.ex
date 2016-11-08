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

  # returns {:ok, connRef} if successful
  def start_persistent_connection(url, receiving_pid) do
   body = ""
   headers = [{"Content-Type", "application/json"}]
   method = :post
   opts = [:async, {:stream_to, receiving_pid}, {:connect_timeout, :infinity}, {:recv_timeout, :infinity}]
   :hackney.request(method, url, headers, body, opts)
  end

  def send_via_raw_tcp(data, connRef) do
    socket = connRef |> :hackney.request_info |> List.last |> elem(1)
    :gen_tcp.send(socket, data)
  end

  def close_persistent_connection(connRef) do
    socket = connRef |> :hackney.request_info |> List.last |> elem(1)
    :gen_tcp.close(socket)
  end

  def add_query_params(url, params) do
    "#{url}?#{URI.encode_query(params)}"
  end
end

