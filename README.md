# rails_graphql_react_tutorial
rails_graphql_react_tutorial

## 参考
- https://zenn.dev/lilac/books/37bdf5d90b5f9b/viewer/ed9812
- https://tech.hey.jp/entry/2021/09/08/175803



## Docker環境構築

### 1. 各種ファイルの準備

```bash
rails_react
├── api/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── Gemfile
│   └── Gemfile.lock
└── docker-compose.yml
```

#### docker-compose.yml

```yml
version: "3"

services:
  api:
    build:
      context: ./api/
      dockerfile: Dockerfile
    ports:
      - "3333:3333"
    volumes:
      - ./api:/var/www/api
      - gem_data:/usr/local/bundle
    command: /bin/sh -c "rm -f /var/www/api/tmp/pids/server.pid && bundle exec rails s -p 3333 -b '0.0.0.0'"
volumes:
  gem_data:
```

#### api/Dockerfile

```Dockerfile
FROM ruby:2.7.1

ARG WORKDIR=/var/www/api
# デフォルトの locale `C` を `C.UTF-8` に変更する
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# タイムゾーンを日本時間に変更
ENV TZ Asia/Tokyo

RUN apt-get update && apt-get install -y nodejs npm mariadb-client
RUN npm install -g yarn@1

RUN mkdir -p $WORKDIR
WORKDIR $WORKDIR

COPY Gemfile $WORKDIR/Gemfile
COPY Gemfile.lock $WORKDIR/Gemfile.lock
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3333

# Start the main process
CMD ["rails", "server", "-p", "3333", "-b", "0.0.0.0"]
```

#### api/Gemfile

```ruby
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.6'
```

#### api/entrypoint.sh

```sh
#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
```

### 2. コンテナ作成

```bash
$ docker-compose run api rails new . --force --api -T
$ docker-compose build
$ docker-compose up -d
$ docker-compose run api rake db:create
```



## Graphql初期設定(Backend)

### 1. Gemの導入

```ruby
gem 'graphql'
group :development do
  gem 'graphiql-rails'
  gem 'sass-rails'
end

```

```bash
$ docker-compose run api bundle install
```



### 2. 各種設定

#### app/assets/config/manifest.js

```js
//= link graphiql/rails/application.css
//= link graphiql/rails/application.js
```



#### config/application.rb

`application.rb`に次の1行を追加とコメントアウト解除

```ruby
require_relative "boot"

require "rails/all"
...
- # require "sprockets/railtie"
+ require "sprockets/railtie" # コメントアウト解除

Bundler.require(*Rails.groups)

module RailsReactGraphql
 class Application < Rails::Application
   config.load_defaults 7.0

   config.api_only = true
 
+  config.middleware.use ActionDispatch::Session::CookieStore # 追加
 end
end
```



### 3. Graphql関連ファイル生成

下記コマンドでGraphql関連のファイルを自動生成

```bash
$ docker-compose run api bundle exec rails g graphql:install
```

↑を実行すると`config/routes.rb`に以下の1行が追記されている。

`config/routes.rb`

```ruby
post "/graphql", to: "graphql#execute"
```

開発環境でgraphiqlを使うためのルーティングを追加する

`config/routes.rb`

```ruby
Rails.application.routes.draw do
  # 以下の3行を追加
+ if Rails.env.development?
+   mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "graphql#execute"
+ end

 post "/graphql", to: "graphql#execute"
 # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

 # Defines the root path route ("/")
 # root "articles#index"
end
```



## Queryの作成(Backend)

### Bookモデルの作成

```bash
$ docker-compose run api bundle exec rails g model Book title:string
$ docker-compose run api bundle exec rails db:migrate
```

Graphql-rubyが提供している、モデルの型ファイルを自動生成するコマンドを実行する

```bash
$ bin/rails generate graphql:object Book
```

`app/graphql/types/`以下にBookモデルの型ファイル`book_type.rb`ファイルが生成される

`app/graphql/types/book_type.rb`

```ruby
# frozen_string_literal: true

module Types
  class BookType < Types::BaseObject
    field :id, ID, null: false
    field :title, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
```



### クエリ作成

`app/graphql/types/query_type.rb`

```ruby
module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

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

```

`app/graphql/types/book_type.rb`

```ruby
# frozen_string_literal: true
module Types
  class BookType < Types::BaseObject
    field :id, ID, null: false
    field :title, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

+   field :dobule_name, String
+   def dobule_name
+   	object.title * 2
+   end
  end
end
```



#### データ作成

`rails console`

```ruby
3.times do |i|
  Book.create!(title: "本 #{i + 1}")
end
```



#### クエリ実行

```json
{
  books {
    id
    title
    dobuleName
  }
}
```



## Mutationの作成(Backend)

### CreateBookMutationの作成

```bash
$ docker-compose run api rails g graphql:mutation CreateBook
```

↑のコマンドを実行することで以下が作成され、mutation_type.rbに1行追加される

`app/app/graphql/mutations/create_book.rb`

```ruby
module Mutations
  class CreateBook < BaseMutation
    # TODO: define return fields
    # field :post, Types::PostType, null: false

    # TODO: define arguments
    # argument :name, String, required: true

    # TODO: define resolve method
    # def resolve(name:)
    #   { post: ... }
    # end
  end
end
```

`app/graphql/types/mutation_type.rb`

```ruby
module Types
  class MutationType < Types::BaseObject
		# 以下が自動で追加される
+   field :create_book, mutation: Mutations::CreateBook
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
```

#### CreateBookMutation実装

```ruby
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
```



## rake task定義

`lib/tasks/graphql.rake`を作成し、以下のように記述する

```ruby
require 'graphql/rake_task'
GraphQL::RakeTask.new(schema_name: 'ApiSchema') 
```

以下のコマンドを実行して、schema.graphqlを作成する

```bash
$ docker-compose run api bin/rake graphql:schema:idl
```



## Graphql初期設定(Frontend)

```bash
$ yarn create react-app frontend --template typescript
```

```bash
$ yarn add @apollo/client graphql
```



### cors設定

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # frontのURL
    origins 'http://localhost:3000'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```



### index.tsx変更

```react
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import {
  ApolloClient,
  InMemoryCache,
  ApolloProvider,
  createHttpLink,
} from "@apollo/client";

const link = createHttpLink({
  uri: "http://localhost:3333/graphql",
  credentials: "include",
});

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

const client = new ApolloClient({
  cache: new InMemoryCache(),
  link: link,
});

root.render(
  <React.StrictMode>
    <ApolloProvider client={client}>
      <App />
    </ApolloProvider>
  </React.StrictMode>
);
```



## codegen設定

### GraphQL Code Generatorのインストール

```bash
$ yarn add -D @graphql-codegen/cli
```

### 設定

```bash
$ yarn graphql-codegen init
```

諸々質問に答えると以下のような、codegen.ymlが生成される

`frontend/codegen.yml`

```yml
overwrite: true
schema: "../api/schema.graphql"
documents: "src/**/*.graphql"
generates:
  src/generated/graphql.tsx:
    plugins:
      - "typescript"
      - "typescript-operations"
      - "typescript-react-apollo"
  ./graphql.schema.json:
    plugins:
      - "introspection"
```

`frontend/package.json`

```json
"scripts": {
    ...
    "codegen": "graphql-codegen --config codegen.yml"
  }
```



### queryファイル作成

`frontend/src/queries/books.graphql`

```graphql
query books {
  books {
    id
    title
  }
}
```



### yarn codegen

```bash
$ yarn codegen
```

`yarn codegen`を実行すると、`frontend/src/generated/graphql.tsx`が自動生成される



### query hooks利用

`frontend/src/App.tsx`

```react
import { useBooksQuery } from "./generated/graphql";

function App() {
  const { data: { books = [] } = {} } = useBooksQuery();

  return (
    <div>
      {books.map((book) => (
        <div key={book.id}>{book.title}</div>
      ))}
    </div>
  );
}
export default App;
```



### mutation生成

`frontend/src/queries/createBook.graphql`

```graphql
mutation createBook($input: CreateBookInput!) {
  createBook(input: $input) {
    book {
      id
      title
    }
  }
}
```

`frontend/src/queries/deleteBook.graphql`

```graphql
mutation deleteBook($id: ID!) {
  deleteBook(input: { id: $id }) {
    book {
      id
    }
  }
}
```



```bash
$ yarn codegen
```

``frontend/src/App.tsx``

```react
import { useBooksQuery, useCreateBookMutation, useDeleteBookMutation } from "./generated/graphql";
import { useState } from "react"

function App() {
  const { data: { books = [] } = {} } = useBooksQuery();
  const [createBook] = useCreateBookMutation({ refetchQueries: ["books"] });
  const [deleteBook] = useDeleteBookMutation({ refetchQueries: ["books"] });
  const [title, setTitle] = useState("");

  return (
    <div>
      <input value={title} onChange={(e) => setTitle(e.target.value)} />
      <button
        onClick={() => {
          createBook({ variables: { input: { title: title } } });
          setTitle("");
        }}
      >
        保存
      </button>
      {books.map((book) => (
        <div key={book.id}>
          <div>{book.title}</div>
          <button onClick={() => deleteBook({ variables: { id: book.id } })}>
            削除
          </button>
        </div>
      ))}
    </div>
  );
}
```