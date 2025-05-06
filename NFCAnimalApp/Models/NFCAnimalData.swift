import Foundation

struct NFCAnimalData: Codable {
    let id: String
    let animalName: String?
    let birthDate: Date
    let gender: String
    let breed: String
    let parentId: String?
    let birthFarmId: String
    let currentFarmId: String
    let transferDate: Date?
    let exportCountry: String?
    let exportDate: Date?
    let deathDate: Date?
    let deathLocation: String?
    let vaccinations: Vaccinations
    let slaughterhouse: Slaughterhouse?
    let farmInformation: FarmInformation
    let ownerInformation: OwnerInformation
    
    init(id: String = UUID().uuidString,
         animalName: String? = nil,
         birthDate: Date,
         gender: String,
         breed: String,
         parentId: String? = nil,
         birthFarmId: String,
         currentFarmId: String,
         transferDate: Date? = nil,
         exportCountry: String? = nil,
         exportDate: Date? = nil,
         deathDate: Date? = nil,
         deathLocation: String? = nil,
         vaccinations: Vaccinations,
         slaughterhouse: Slaughterhouse? = nil,
         farmInformation: FarmInformation,
         ownerInformation: OwnerInformation) {
        self.id = id
        self.animalName = animalName
        self.birthDate = birthDate
        self.gender = gender
        self.breed = breed
        self.parentId = parentId
        self.birthFarmId = birthFarmId
        self.currentFarmId = currentFarmId
        self.transferDate = transferDate
        self.exportCountry = exportCountry
        self.exportDate = exportDate
        self.deathDate = deathDate
        self.deathLocation = deathLocation
        self.vaccinations = vaccinations
        self.slaughterhouse = slaughterhouse
        self.farmInformation = farmInformation
        self.ownerInformation = ownerInformation
    }
}

struct Vaccinations: Codable {
    let sapVaccine: Date?
    let brucellaVaccine: Date?
    let pasteurellaVaccine: Date?
    let otherVaccine: Date?
    
    init(sapVaccine: Date? = nil,
         brucellaVaccine: Date? = nil,
         pasteurellaVaccine: Date? = nil,
         otherVaccine: Date? = nil) {
        self.sapVaccine = sapVaccine
        self.brucellaVaccine = brucellaVaccine
        self.pasteurellaVaccine = pasteurellaVaccine
        self.otherVaccine = otherVaccine
    }
    
    private enum CodingKeys: String, CodingKey {
        case sapVaccine
        case brucellaVaccine
        case pasteurellaVaccine
        case otherVaccine
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ISO8601DateFormatter()
        
        if let date = sapVaccine {
            try container.encode(dateFormatter.string(from: date), forKey: .sapVaccine)
        }
        if let date = brucellaVaccine {
            try container.encode(dateFormatter.string(from: date), forKey: .brucellaVaccine)
        }
        if let date = pasteurellaVaccine {
            try container.encode(dateFormatter.string(from: date), forKey: .pasteurellaVaccine)
        }
        if let date = otherVaccine {
            try container.encode(dateFormatter.string(from: date), forKey: .otherVaccine)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ISO8601DateFormatter()
        
        func decodeDate(forKey key: CodingKeys) -> Date? {
            if let dateString = try? container.decodeIfPresent(String.self, forKey: key) {
                return dateFormatter.date(from: dateString)
            }
            return nil
        }
        
        self.sapVaccine = decodeDate(forKey: .sapVaccine)
        self.brucellaVaccine = decodeDate(forKey: .brucellaVaccine)
        self.pasteurellaVaccine = decodeDate(forKey: .pasteurellaVaccine)
        self.otherVaccine = decodeDate(forKey: .otherVaccine)
    }
}

struct Slaughterhouse: Codable {
    let name: String
    let address: String
    let licenseNumber: String
    let slaughterDate: Date
}

struct FarmInformation: Codable {
    let countryCode: String
    let provinceCode: String
    let farmId: String
    let address: String
    let coordinates: String
    let phone: String
    let fax: String?
    let email: String?
    
    init(countryCode: String,
         provinceCode: String,
         farmId: String,
         address: String,
         coordinates: String,
         phone: String,
         fax: String? = nil,
         email: String? = nil) {
        self.countryCode = countryCode
        self.provinceCode = provinceCode
        self.farmId = farmId
        self.address = address
        self.coordinates = coordinates
        self.phone = phone
        self.fax = fax
        self.email = email
    }
}

struct OwnerInformation: Codable {
    let firstName: String
    let lastName: String
    let idNumber: String
    let address: String
    
    init(firstName: String,
         lastName: String,
         idNumber: String,
         address: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.idNumber = idNumber
        self.address = address
    }
}

// MARK: - Codable Extensions
extension NFCAnimalData {
    private enum CodingKeys: String, CodingKey {
        case id
        case animalName
        case birthDate
        case gender
        case breed
        case parentId
        case birthFarmId
        case currentFarmId
        case transferDate
        case exportCountry
        case exportDate
        case deathDate
        case deathLocation
        case vaccinations
        case slaughterhouse
        case farmInformation
        case ownerInformation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ISO8601DateFormatter()
        
        func decodeDate(_ key: CodingKeys) throws -> Date? {
            if let dateString = try container.decodeIfPresent(String.self, forKey: key) {
                return dateFormatter.date(from: dateString)
            }
            return nil
        }
        
        id = try container.decode(String.self, forKey: .id)
        animalName = try? container.decodeIfPresent(String.self, forKey: .animalName)
        birthDate = try decodeDate(.birthDate) ?? Date()
        gender = try container.decode(String.self, forKey: .gender)
        breed = try container.decode(String.self, forKey: .breed)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        birthFarmId = try container.decode(String.self, forKey: .birthFarmId)
        currentFarmId = try container.decode(String.self, forKey: .currentFarmId)
        transferDate = try decodeDate(.transferDate)
        exportCountry = try container.decodeIfPresent(String.self, forKey: .exportCountry)
        exportDate = try decodeDate(.exportDate)
        deathDate = try decodeDate(.deathDate)
        deathLocation = try container.decodeIfPresent(String.self, forKey: .deathLocation)
        vaccinations = try container.decode(Vaccinations.self, forKey: .vaccinations)
        slaughterhouse = try container.decodeIfPresent(Slaughterhouse.self, forKey: .slaughterhouse)
        farmInformation = try container.decode(FarmInformation.self, forKey: .farmInformation)
        ownerInformation = try container.decode(OwnerInformation.self, forKey: .ownerInformation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let dateFormatter = ISO8601DateFormatter()
        
        func encodeDate(_ date: Date?, for key: CodingKeys) throws {
            if let date = date {
                try container.encode(dateFormatter.string(from: date), forKey: key)
            }
        }
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(animalName, forKey: .animalName)
        try encodeDate(birthDate, for: .birthDate)
        try container.encode(gender, forKey: .gender)
        try container.encode(breed, forKey: .breed)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(birthFarmId, forKey: .birthFarmId)
        try container.encode(currentFarmId, forKey: .currentFarmId)
        try encodeDate(transferDate, for: .transferDate)
        try container.encodeIfPresent(exportCountry, forKey: .exportCountry)
        try encodeDate(exportDate, for: .exportDate)
        try encodeDate(deathDate, for: .deathDate)
        try container.encodeIfPresent(deathLocation, forKey: .deathLocation)
        try container.encode(vaccinations, forKey: .vaccinations)
        try container.encodeIfPresent(slaughterhouse, forKey: .slaughterhouse)
        try container.encode(farmInformation, forKey: .farmInformation)
        try container.encode(ownerInformation, forKey: .ownerInformation)
    }
}

extension NFCAnimalData {
    func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    static func fromJSON(_ jsonString: String) throws -> NFCAnimalData? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(NFCAnimalData.self, from: data)
    }
} 