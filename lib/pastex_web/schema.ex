defmodule PastexWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias PastexWeb.ContentResolver

  import_types PastexWeb.Schema.{ContentTypes, IdentityTypes}

  # Every field has a resolver! If you don't specify one, then we default to Map.get() essentially...
  # Most of the course is just about making the resolvers work in a more pleasant way...

  # query | mutation | subscription

  @desc "Can even document the root query to give a lay of the land..."

  query do
    field :health, :string do
      resolve(fn root, _, _ ->
        IO.puts("Executing health...")
        # Root value is an empty map by default...
        # Might want to change for the sake of early-stage prototyping...
        IO.inspect(root)
        {:ok ,"up"}
      end)
    end

    field :explode, :string do
      resolve(fn _,  _, _ ->
        {:error, "Kaboom!"}
      end)
    end


    # Nice nesting for code structure...

    import_fields :content_queries
    import_fields :identity_queries
  end

  mutation do
    # same... :content_mutations defined in ContentTypes

    import_fields :content_mutations
    import_fields :identity_mutations
  end

  # UNIFORM REPR... REALTIME UPDATES AND HTTP REQS...

  # Topic could be e.g. id of the specific entry, or the user to notify...
  # subscriptions in ETS...

  # Kitchen stations could be so straightforward...
  # Menu changes, etc...

#  subscription do
#    # Subscription fields require more configuration... when does a subscription get run... triggered by other things...
#    # reaction to an event that occurred...
#    field :paste_created, :paste do
#
#      # To make subscription require auth...
#      # Take advantage of config resolution struct (second arg...)...
#      # resolution.context.current_user -> {:ok, topic...}
#      # otherwise return error in config function to block realtime connection...
#
#      # GraphQL error handling conventions around subscriptions are still not established well...
#      # Apollo will throw its hands up if it hits an error for subscription...
#
#      # Could architect topics so user gets subscribed to topic with restricted visibility level scoped to themself...
#      # e.g. subscription(visibility:"private") take arg at top-level subscription...
#      # topic:"private:#{user_id}"
#
#      config fn _args, _resolution ->
#        # need to return topic we are subscribing to...
#        {:ok, topic: "*"}
#      end
#
#      # Do not need to use trigger mechanism if we don't like it...
#      # Could also simply do `Absinthe.Subscription.Publish` explicitly in the create_paste function
#      # content resolver... instead of specifying trigger here...
#      # Happens at application-layer taking advantage of Phoenix pub sub (or other)
#      # There are typescript absinthe subscription packages...
#      # https://github.com/absinthe-graphql/absinthe-socket/tree/master/packages/socket
#
#      trigger [:create_paste], topic: fn _paste ->
#        # We are broadcasting to all (* convention) whenever a paste is created...
#        "*"
#      end
#    end
#  end

  subscription do
    field :paste_created, :paste do
      arg :visibility, :string, default_value: "public"

      config fn %{visibility: visibility}, %{context: context} ->
        context |> IO.inspect()

        case {visibility, context} do
          {"public", _} ->
            {:ok, topic: "public"}

          {"private", %{current_user: %{id: user_id}}} ->
            {:ok, topic: "private:#{user_id}"}

          _ ->
            {:error, "unauthorized"}
        end
      end

      trigger :create_paste,
              topic: fn paste ->
                if paste.visibility == "public" do
                  ["public"]
                else
                  ["private:#{paste.author_id}"]
                end
              end
    end
  end

  # We still need to connect our objects to the query entry-point by adding a field...

  # Do not have to limit ourselves to maps... could use structs... and field names could
  # differ from map keys... Absinthe has an access method... e.g. may want to rename "inserted_at"
  # field to more user-relevant "creation_time" when accessing...


  # Error path -> nested lookup into field with the source of the error...


  # Use batching & dataloader to avoid n+1 queries... should *not* be doing queries
  # directly in resolver... accrue entries in batch... then call function with batch...
  # batched single database call, then return results to corresponding resolvers...

  # Can analyze query before we actually execute it... the query is a data structure...
  # Use instrumentation, store commonly used queries to identify what we should spend effort optimizing...
  # See when we can deprecate fields based on usage...

  defp tracing_middleware() do
    [ApolloTracing.Middleware.Tracing]
  end

  def middleware(middleware, _field, _obj) do
    tracing_middleware() ++ [PastexWeb.Middleware.Auth | middleware]
  end

end
