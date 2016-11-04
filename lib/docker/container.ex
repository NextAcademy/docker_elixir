defmodule Docker.Container do
  alias Docker.Client

  def all(host, opts \\ %{}) do
    "#{host}/containers/json"
    |> Client.add_query_params(opts)
    |> Client.get!
    |> parse_all_response
  end

  # no idea how to trigger bad paramter and server error cases
  defp parse_all_response(%{status_code: 400}), do: {:error,:bad_parameter}
  defp parse_all_response(%{status_code: 500}), do: {:error,:server_error}
  defp parse_all_response(%{body: body}) when is_list(body), do:  {:ok, body}

  def list(host, opts \\ %{}) do
    case all(host, opts) do
      {:ok, list} -> Enum.map(list, &(&1["Id"]))
      {:error, reason} -> {:error, reason}
    end
  end

  # refer to https://docs.docker.com/engine/reference/api/docker_remote_api_v1.24/#/create-a-container
  def create(host, opts \\ %{}) do
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
  defp parse_start_response(%{status_code: 304}), do: {:error, :contianer_already_started}
  defp parse_start_response(%{status_code: 404}), do: {:error, :no_such_container}
  defp parse_start_response(%{status_code: 500}), do: {:error, :server_error}

  def run(host, opts \\ %{}) do
    case create(host, opts) do
      {:ok, %{id: id}} -> start(host, id)
      {:error, reason} -> {:error, reason}
    end
  end

  def stop(host, container_id, t \\ 0) do
    "#{host}/containers/#{container_id}/stop"
    |> Client.add_query_params(%{t: t})
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
end

