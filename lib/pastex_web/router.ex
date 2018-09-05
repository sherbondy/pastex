defmodule PastexWeb.Router do
  use PastexWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    # Add plug for handling session tokens for absinthe...
    plug(PastexWeb.Context)
  end

  # Got rid of namespacing to PastexWeb...
  scope "/" do
    pipe_through(:api)

    # Add endpoint for graphiql playground...
    # It is included in the absinthe plug...
    # Send all requests (get, post, etc.) to graphiql for processing...
    # Specify default phoenix websocket for subscriptions...

    forward("/graphiql", Absinthe.Plug.GraphiQL,
      schema: PastexWeb.Schema,
      interface: :playground,
      socket: PastexWeb.UserSocket,
      pipeline: {ApolloTracing.Pipeline, :plug},
      analyze_complexity: true,
      max_complexity: 10_000
    )
  end
end
