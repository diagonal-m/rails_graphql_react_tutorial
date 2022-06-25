module Mutations
  class DeleteBook < BaseMutation
    graphql_name 'DeleteBook'

    field :book, Types::BookType, null: true
    field :result, Boolean, null: true

    argument :id, ID, required: false

    def resolve(id:)
      book = Book.find(id)
      book.destroy
      {
        book: book,
        result: book.errors.blank?
      }
    end
  end
end
