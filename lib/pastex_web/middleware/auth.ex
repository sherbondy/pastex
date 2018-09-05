defmodule PastexWeb.Middleware.Auth do
  @behavior Absinthe.Middleware

  alias Pastex.Identity

  # Adding @behavior tag forces us to implement the interface... throws compiler warning otherwise...
  # This is specified in Absinthe.Middleware as @callback... forces things with behavior to implement...
  # @behavior and @protocol...

  # @impl makes it more clear that we are implementing a specific callback... can also hint the name
  # of the specific behavior we are implementing...
  # e.g. @impl Absinthe.Middleware
  # so the compiler can help us verify...

  # Middleware lets you hook into resolution from resolver, like a plug pipeline...
  # transform the resolution, return a new modified one...

  # This middleware will be applied to every field in the schema!

  # More general version of our previous specific authorized resolver for the email field, now applied to all fields!

  @impl true
  def call(resolution, _) do
    # source is an older name that corresponds to "parent" in resolve fn (first arg)
    entity = resolution.source
    # dynamically look up the name of the field we are currently on, e.g. :email, etc...
    key = resolution.definition.schema_node.identifier
    current_user = resolution.context[:current_user]

    if Identity.authorized?(entity, key, current_user) do
      resolution
    else
      Absinthe.Resolution.put_result(resolution, {:error, "Unauthorized"})
    end
  end

end
