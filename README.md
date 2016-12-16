# Docker

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `docker` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:docker, "~> 0.1.0"}]
    end
    ```

  2. Ensure `docker` is started before your application:

    ```elixir
    def application do
      [applications: [:docker]]
    end
    ```


# Configuration

```
password = System.get_env("DOCKER_HOST_TLS_PW")

if is_binary(password) do
  config :docker_elixir,
  ssl_options: [
    cacertfile: System.get_env("DOCKER_HOST_CACERT"),
    certfile: System.get_env("DOCKER_HOST_CERT"),
    keyfile: System.get_env("DOCKER_HOST_KEY"),
    password: String.to_charlist(password)
  ]
end
```
