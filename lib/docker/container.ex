defmodule Docker.Container do
  alias Docker.Client

  def all(host, opts \\ %{}) do
    "#{host}/containers/json"
    |> Client.add_query_params(opts)
    |> Client.get!
    |> parse_all_response
  end

  defp parse_all_response(%{status_code: 400}), do: {:error,:bad_parameter}
  defp parse_all_response(%{status_code: 500}), do: {:error,:server_error}
  defp parse_all_response(%{body: body}) when is_list(body), do:  {:ok, body}

  def list(host, opts \\ %{}) do
    case all(host, opts) do
      {:ok, list} -> Enum.map(list, &(&1["Id"]))
      {:error, reason} -> {:error, reason}
    end
  end

  @default_creation_params %{
      "Image"        => "nextacademy/ruby",
      "Tty"          => true,
      "OpenStdIn"    => true,
      "AttachStdin"  => true,
      "AttachStdout" => true,
      "AttachStderr" => true,
      "Cmd"          => ["bash"]
  }

  # refer to https://docs.docker.com/engine/reference/api/docker_remote_api_v1.24/#/create-a-container
  def create(host, opts \\ @default_creation_params) do
    "#{host}/containers/create"
    |> Client.post_json!(opts)
    |> parse_create_response
  end

  defp parse_create_response(%{status_code: 500}), do: {:error,:server_error}
  defp parse_create_response(%{status_code: 404}), do: {:error,:no_such_image}
  defp parse_create_response(%{body: %{"Id" => id}}), do: {:ok, %{id: id}}

  def start(host, container_id, opts \\ %{}) do
    "#{host}/containers/#{container_id}/start"
    |> Client.post_json!(opts)
    |> parse_start_response


  end

  defp parse_start_response(%{status_code: 204}), do: {:ok, :no_error}
  defp parse_start_response(%{status_code: 304}), do: {:error, :container_already_started}
  defp parse_start_response(%{status_code: 404}), do: {:error, :no_such_container}
  defp parse_start_response(%{status_code: 500}), do: {:error, :server_error}

  def run(host, opts \\ @default_creation_params) do
    case create(host, opts) do
      {:ok, %{id: id}} -> 
        case start(host, id) do
          {:ok, _} -> {:ok, %{id: id}}
          {:error, reason} -> {:error, :reason}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  def stop(host, container_id, opts \\ %{}) do
    "#{host}/containers/#{container_id}/stop"
    |> Client.add_query_params(opts)
    |> Client.post_json!
    |> parse_stop_response 
  end

  defp parse_stop_response(%{status_code: 204}), do: {:ok, :no_error}
  defp parse_stop_response(%{status_code: 304}), do: {:error, :container_already_stopped}
  defp parse_stop_response(%{status_code: 404}), do: {:error, :no_such_container}
  defp parse_stop_response(%{status_code: 500}), do: {:error, :server_error}

  def remove(host, container_id, opts \\ %{}) do
    "#{host}/containers/#{container_id}"
    |> Client.add_query_params(opts)
    |> Client.delete!
    |> parse_remove_response 
  end

  defp parse_remove_response(%{status_code: 204}), do: {:ok, :no_error}
  defp parse_remove_response(%{status_code: 400}), do: {:error, :bad_parameter}
  defp parse_remove_response(%{status_code: 404}), do: {:error, :no_such_container}
  defp parse_remove_response(%{status_code: 409}), do: {:error, :conflict}
  defp parse_remove_response(%{status_code: 500}), do: {:error, :server_error}

  def kill(host, container_id, stop_opts \\ %{}, remove_opts \\ %{}) do
    case stop(host, container_id, stop_opts) do
      {:ok, _} -> remove(host, container_id, remove_opts)
      {:error, :container_already_stopped} -> remove(host, container_id, remove_opts)
      error_message -> error_message
    end
  end

  def exec_create(host, container_id, opts \\ %{}) do
    "#{host}/containers/#{container_id}/exec"
    |> Client.post_json!(opts)
    |> parse_exec_create_response
  end

  defp parse_exec_create_response(%{status_code: 404}), do: {:error, :no_such_container}
  defp parse_exec_create_response(%{status_code: 409}), do: {:error, :container_paused}
  defp parse_exec_create_response(%{status_code: 500}), do: {:error, :server_error}
  defp parse_exec_create_response(%{body: %{"Id" => id}}), do: {:ok, %{id: id}}

  # bash is not required to be prepended
  # Docker.Container.exec_stream host, id, %{"Cmd" => ["rspec", "test.rb"], "AttachStdout" => true, "AttachStderr" => true}
  def exec_start(host, exec_id, %{"Detach" => true}) do
    "#{host}/exec/#{exec_id}/start"
    |> Client.post_json!(%{"Detached" => true})
    |> parse_exec_start_response
  end

  def exec_start(host, exec_id, opts) do
    "#{host}/exec/#{exec_id}/start"
    |> Client.post_json!(opts, stream_to: self)
    |> parse_exec_start_response
  end
  # how to handle stream?
  defp parse_exec_start_response(%{status_code: 200}), do: {:ok, :exec_successful}
  defp parse_exec_start_response(%{status_code: 204}), do: {:ok, :streaming_started}
  defp parse_exec_start_response(%{status_code: 404}), do: {:error, :no_such_container}
  defp parse_exec_start_response(%{status_code: 409}), do: {:error, :container_paused}
  defp parse_exec_start_response(%HTTPoison.AsyncResponse{id: ref}), do: {:ok, ref} 

  def exec_detached(host, container_id, create_opts \\ %{}) do
    case exec_create(host, container_id, create_opts) do
      {:ok, %{id: exec_id}} ->
        exec_start(host, exec_id, %{"Detach" => true})
      {:error, reason} -> {:error, reason}
    end
  end

  def exec_stream(host, container_id, create_opts \\ %{}) do
    case exec_create(host, container_id, create_opts) do
      {:ok, %{id: exec_id}} ->
        case exec_start(host, exec_id, %{}) do
          {:ok, _} -> stream_response
          {:error, reason} -> {:error, reason}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  def logs(host, container_id, opts \\%{stdout: 1, stderr: 1}) do
    "#{host}/containers/#{container_id}/logs"
    |> Client.add_query_params(opts)
    |> Client.get!
    |> parse_logs_response
  end

  defp parse_logs_response(response), do: IO.inspect response 

  def logs_stream(host, container_id, opts  \\ %{}) do
    "#{host}/containers/#{container_id}/logs"
    |> Client.add_query_params(opts)
    |> Client.get!([], [stream_to: self])
    |> parse_logs_stream_response
  end

  defp parse_logs_stream_response(%HTTPoison.AsyncResponse{id: _ref}), do: stream_response

  defp stream_response(output \\ []) do
    receive do
      %HTTPoison.AsyncChunk{chunk: new_output} -> 
        total_output = output ++ [new_output]
        stream_response(total_output)
      %HTTPoison.AsyncEnd{id: _ref} ->
        Enum.map(output, fn(chunk) -> 
          if String.printable?(chunk), do: chunk, else: String.split_at(chunk, 8) |> elem(1)
        end)
      _ ->
        stream_response(output)
    end
  end
end

