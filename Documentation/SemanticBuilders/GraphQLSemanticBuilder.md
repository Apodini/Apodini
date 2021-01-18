![concept](https://apodini.github.io/resources/markdown-labels/document_type_concept.svg)

### Purpose

We are going to talk about the user input and GrapQL parse in this markdown file. We will consider many examples that
aim to help the user understanding the GraphQL exporter. GraphQL engine will serve in the `/graphl` endpoint as a POST
request. So, one can send a request to the aforementioned endpoint. Furthermore, GraphQL IDE will serve in the `/graphl`
endpoint as a GET request. More precisely, if one visited `/graphql` endpoint in the browser, the website will serve the
GraphQL IDE.

### Mapping

<table>
<tr>
<th>Apodini DSL</th>
<th>GraphQL Schema</th>
</tr>
<tr>
<td>

```swift
Group("swift") {
    Text("Hello Swift! 💻")
}
```

</td>
<td>

```graphql  
type Query {
   swift: String!
}
```

</td>
</tr>
<tr>
<td>

```swift
Group("book") {
    Group("author") {
        Group("name") {
            Text("Jules Verne")
        }
        Group("born") {
            Text("February 8, 1828")
        }
    }
    Group("name") {
        Text("Around the World in Eighty Days")
    }
    Group("genre") {
        Text("Adventure fiction")
    }
    Group("description") {
        Text("Around the World in Eighty Days is an adventure novel ...")
    }
}
```

</td>
<td>

```graphql  
type Author {
    name: String!
    born: String!
}

type Book {
  author: Author!
  name: String!
  genre: String!
  description: String!
}

type Query {
  Book() : Book 
  Author() : Author 
}
```

</td>
</tr>
<tr>
<td>

```swift
struct User: Codable {
    var id: Int
    var name: String
}

struct UserHandler: Handler {
    @Parameter var userId: Int
    @Parameter var userName: String?

    func handle() -> User {
        User(id: userId, name: userName ?? "Apodini")
    }
}

Group("user") {
    UserHandler(userId: $userId)
}
```

</td>
<td>

```graphql  
type User {
    id: Int!
    name: String
}

type Query {
  User(userId: Int!, userName: String) : User 
}
```

</td>
</tr>
<tr>
<td>

```swift
struct Author {
    let name: String
    let surname: String
}

struct AuthorHandler: Handler {

    func handle() -> Author {
        return Author()
    }
}

struct Book {
    let name: String
    let author: [AuthorComponent]
}

struct BookHandler: Handler {
    @Parameter var id: Idenfiable

    func handle() -> Book {
        return Book()
    }
}


BookHandler() 
```

</td>
<td>

```graphql  
type Author {
    name: String!
    surname: String!
}

type Book {
    id: ID!
    author: [Author]!
    name: String!

}

type Query {
    book : Book 
    author : Author 
}
```

</td>
</tr>
</table>
