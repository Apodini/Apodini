### Purpose
We are going to talk about the user input and GrapQL parse in this markdown file. We will consider many examples that
aim to help the user understanding the GraphQL semantic builder. GraphQL engine will serve in the `/graphl` endpoint.

### Mapping
#### Text Component
The user can define the components as the following.
```swift
Text("Hello World! 👋")
    .httpMethod(.POST)
```         
The engine can answer the following query.
```graphql   
query {
 text
}
```
When someone sends this query, the response will the string that lies inside the component which is `Hello World! 👋` in
our example.

#### Group Component

The user can define the components as the following.
```swift
Group("book") {
    Group("name") {
        Text("Around the World in Eighty Days")
    }
    Text("Around the World in Eighty Days is an adventure novel that ...")
}
```         
The engine can answer the following query.
```graphql   
query {
    book {
        name {
            text
        }
    text
    }
}
```
When someone sends this query, the `text` will return the string results.

-------------------------------------------
The user can define the components as the following.
```swift
Group("book") {
    Group("name") {
        Text("Around the World in Eighty Days")
    }
    Text("Around the World in Eighty Days is an adventure novel that ...")
    Group("author") {
        Group("name") {
            Text("Jules Verne")
        }
        Group("country") {
            Text("French")
        }
    }
}
```         
The code will generate a GraphQL engine that runs in the `/graphl` endpoint. The engine can answer the following query.
```graphql   
query {
    book {
        name {
            text
        }
        author {
            name {
                text
            }
            country {
                text
            }
        }
    text
    }
}
```
When someone sends this query, the `text` will return the string results.


#### Creating Own Component
The user can define the components as the following.
```swift
struct Book {
    var name : String
    var author : String
}
struct BookComponent : Component {
    @Parameter // Property Wrapper
    var id : Idenfiable 
    
    func handle() -> Book {
        // Fetch from database
        return Book()
    }
}

Group("book") {
    BookComponent() { }
}
```      
The code will generate a GraphQL engine that runs in the `/graphl` endpoint. The engine can answer the following query.
```graphql   
query {
    book(id: 12) {
        name
        author
    }
}
```
When someone sends this query, the `name` and the `author` of the `book` with id `12` will be returned.

#### Combined Components
The user can define the components as the following.
```swift
struct Author {
    let name: String
    let surname : String
}

struct AuthorComponent : Component {

    func handle() -> Author {
        return Author()
    }
}

struct Book {
    let name : String
    let author : [AuthorComponent]
}
struct BookComponent : Component {
    @Parameter // Property Wrapper
    var id : Idenfiable 
    
    func handle() -> Book {
        // Fetch from database
        return Book()
    }
}
Group("book") {
    BookComponent() { }
}
```      
The code will generate a GraphQL engine that runs in the `/graphl` endpoint. The engine can answer the following query.
```graphql   
query {
    book(id: 12) {
        author {
            name
            surname
        }
        name
    }
}
```
When someone sends this query, the `name` and the all `author` information of the `book` with id `12` will be returned.

        
 
