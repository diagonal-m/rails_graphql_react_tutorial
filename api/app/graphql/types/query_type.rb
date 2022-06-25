module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :books, [Types::BookType], null: false
    def books
      Book.all.order(:id)
    end

    field :book, Types::BookType, null: false do
      argument :id, Int, required: false
    end
    def book(id:)
      # ↓の値がBookTypeに渡される
      Book.find(id)
    end
  end
end
