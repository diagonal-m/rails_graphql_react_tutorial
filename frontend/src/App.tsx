import { 
  useBooksQuery,
  useCreateBookMutation,
  useDeleteBookMutation,
  useUpdateBookMutation
} from "./generated/graphql";
import { useState } from "react"

function App() {
  const { data: { books = [] } = {} } = useBooksQuery();
  const [createBook] = useCreateBookMutation({ refetchQueries: ["books"] });
  const [deleteBook] = useDeleteBookMutation({ refetchQueries: ["books"] });
  const [updateBook] = useUpdateBookMutation();
  const [title, setTitle] = useState("");

  return (
    <div style={{ width: "400px", margin: " 40px auto" }}>
      <h1>書籍一覧</h1>
      <div style={{ display: "flex", gap: "10px", marginBottom: "40px" }}>
        <input value={title} onChange={(e) => setTitle(e.target.value)} />
        <button
          onClick={() => {
            createBook({ variables: { input: { title: title } } });
            setTitle("");
          }}
        >
          保存
        </button>
      </div>
        {books.map((book) => (
          <div 
            key={book.id}
            style={{ display: "flex", gap: "10px", marginBottom: "10px" }}
          >
            <input
              value={book.title || ""}
              onChange={(e) =>
                updateBook({variables: {
                  id: book.id,
                  title: e.target.value 
                }})
              }
            />
            <button onClick={() => deleteBook({ variables: { id: book.id } })}>
              削除
            </button>
          </div>
        ))}
      </div>
  );
}

export default App;
