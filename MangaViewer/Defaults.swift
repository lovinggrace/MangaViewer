import Foundation

public enum Defaults {
    @Storage(key: "lastPage", defaultValue: [:]) public static var lastPage: [String: String]
}

@propertyWrapper
public struct Storage<Value: Codable> {
    private let key: String
    private let defaultValue: Value
    
    init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: Value {
        get {
            // Read value from UserDefaults
            if let data = UserDefaults.standard.object(forKey: key) as? Data,
               let value = try? JSONDecoder().decode(Value.self, from: data) {
                return value
            }
            return defaultValue
        }
        set {
            // Set value to UserDefaults
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}

