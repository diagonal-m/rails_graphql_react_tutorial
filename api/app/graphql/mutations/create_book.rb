module Mutations
  class CreateBook < BaseMutation
    graphql_name 'CreateBook'

    field :book, Types::BookType, null: true
    field :result, Boolean, null: true

    argument :title, String, required: false

    def resolve(title:)
      book = Book.create(title: title)
      {
        book: book,
        result: book.errors.blank?
      }
    end
  end
end
