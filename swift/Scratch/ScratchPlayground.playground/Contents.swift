import Foundation



protocol NameContaining {
    var firstName: String { get }
    var lastName: String { get }
    var fullName: String { get }
}

extension NameContaining {
    // Provides a default implementation for the 'NameContaining' protocol
    var fullName: String {
        firstName + " " + lastName
    }
}


struct Person: NameContaining {
    let firstName: String
    let lastName: String
}

struct Pet: NameContaining {
    let firstName: String
    let lastName: String
}


var cat = Pet(firstName: "Mr", lastName: "Wiskers")
var dog = Pet(firstName: "Fido", lastName: "Bark")

print("\(cat.fullName), \(dog.fullName) ")
