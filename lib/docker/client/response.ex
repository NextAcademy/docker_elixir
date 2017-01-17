defmodule Docker.Client.Response do
  @moduledoc """
    This module parses the response from HTTPoison
  """

  def parse(%{status_code: 200, body: body}, :all) when is_list(body) do
    {:ok, body}
  end

  def parse(%{status_code: 201, body: %{"Id" => id}}, :create) do
    {:ok, %{id: id}}
  end

  def parse(%{status_code: 204}, :start), do: {:ok, :no_error}

  def parse(%{status_code: 204}, :stop), do: {:ok, :no_error}

  def parse(%{status_code: 304}, :stop), do: {:error, :container_already_stopped}

  def parse(%{status_code: 204}, :remove), do: {:ok, :no_error}

  def parse(%{status_code: 201, body: %{"Id" => id}}, :exec_create) do
    {:ok, %{id: id}}
  end

  def parse(%HTTPoison.AsyncResponse{id: ref}, :exec_start), do: {:ok, ref}
  def parse(%{status_code: 200}, :exec_start), do: {:ok, :no_error}
  # wildcard parse response for all errors, must be at bottom of the file for pattern matching
  def parse(%{body: reason}, _), do: {:error, reason}
end
