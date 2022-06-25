module Mutations
  class UpdateBook < BaseMutation
    graphql_name 'UpdateBook'

    field :book, Types::BookType, null: true
    field :result, Boolean, null: true

    argument :id, ID, required: true
    argument :title, String, required: false

    def resolve(id:, title:)
      book = Book.find(id)
      book.update(title: title)
      {
        book: book,
        result: book.errors.blank?
      }
    end
  end
end
