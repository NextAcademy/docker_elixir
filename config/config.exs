use Mix.Config

# default options
config :docker_elixir,
        ssl_options: []

# add config for in the phoenix as follows
#password = System.get_env("DOCKER_HOST_TLS_PW")

#if is_binary(password) do
  #config :docker_elixir,
  #ssl_options: [
    #cacertfile: System.get_env("DOCKER_HOST_CACERT"),
    #certfile: System.get_env("DOCKER_HOST_CERT"),
    #keyfile: System.get_env("DOCKER_HOST_KEY"),
    #password: String.to_charlist(password)
  #]
#end
