import SwiftUI
import FirebaseFirestore
import UIKit

// MARK: - Search Section View
struct SearchSectionView: View {
    @Binding var searchID: String
    let onSearch: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search by Animal ID")
                .font(.headline)
                .foregroundColor(Theme.darkGreen)
            
            HStack {
                TextField("Enter Animal ID", text: $searchID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(10)
                    .background(Theme.cream.opacity(0.2))
                    .cornerRadius(8)
                
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Theme.rust)
                        .cornerRadius(8)
                }
                .disabled(searchID.isEmpty || isLoading)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(Theme.darkGreen)
            .padding(.bottom, 5)
    }
}

// MARK: - Info Card View
struct InfoCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Basic Info Section
struct BasicInfoSection: View {
    let animal: NFCAnimalData
    
    var body: some View {
        Group {
            InfoRow(title: "ID", value: animal.id)
            InfoRow(title: "Gender", value: animal.gender.isEmpty ? "null" : animal.gender)
            InfoRow(title: "Breed", value: animal.breed.isEmpty ? "null" : animal.breed)
            InfoRow(title: "Birth Date", value: formatDate(animal.birthDate))
            InfoRow(title: "Parent ID", value: animal.parentId ?? "null")
            InfoRow(title: "Birth Farm ID", value: animal.birthFarmId.isEmpty ? "null" : animal.birthFarmId)
            InfoRow(title: "Current Farm ID", value: animal.currentFarmId.isEmpty ? "null" : animal.currentFarmId)
        }
    }
}

// MARK: - Additional Info Section
struct AdditionalInfoSection: View {
    let animal: NFCAnimalData
    
    var body: some View {
        Group {
            if let transferDate = animal.transferDate {
                InfoRow(title: "Transfer Date", value: formatDate(transferDate))
            }
            
            if let exportCountry = animal.exportCountry {
                InfoRow(title: "Export Country", value: exportCountry)
            }
            
            if let exportDate = animal.exportDate {
                InfoRow(title: "Export Date", value: formatDate(exportDate))
            }
            
            if let deathDate = animal.deathDate {
                InfoRow(title: "Death Date", value: formatDate(deathDate))
            }
            
            if let deathLocation = animal.deathLocation {
                InfoRow(title: "Death Location", value: deathLocation)
            }
        }
    }
}

// MARK: - Vaccinations Section
struct VaccinationsSection: View {
    let vaccinations: Vaccinations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vaccination Information")
                .font(.headline)
            
            if let date = vaccinations.sapVaccine {
                VaccineRow(name: "SAP Vaccine", date: date)
            }
            if let date = vaccinations.brucellaVaccine {
                VaccineRow(name: "Brucella Vaccine", date: date)
            }
            if let date = vaccinations.pasteurellaVaccine {
                VaccineRow(name: "Pasteurella Vaccine", date: date)
            }
            if let date = vaccinations.otherVaccine {
                VaccineRow(name: "Other Vaccine", date: date)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct VaccineRow: View {
    let name: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(name)
                .font(.subheadline)
                .bold()
            Text("Date: \(formatDate(date))")
                .font(.subheadline)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Farm Information Section
struct FarmInformationSection: View {
    let farmInfo: FarmInformation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Farm Information")
                .font(.headline)
            
            InfoRow(title: "Country Code", value: farmInfo.countryCode.isEmpty ? "null" : farmInfo.countryCode)
            InfoRow(title: "Province Code", value: farmInfo.provinceCode.isEmpty ? "null" : farmInfo.provinceCode)
            InfoRow(title: "Farm ID", value: farmInfo.farmId.isEmpty ? "null" : farmInfo.farmId)
            InfoRow(title: "Address", value: farmInfo.address.isEmpty ? "null" : farmInfo.address)
            InfoRow(title: "Coordinates", value: farmInfo.coordinates.isEmpty ? "null" : farmInfo.coordinates)
            InfoRow(title: "Phone", value: farmInfo.phone.isEmpty ? "null" : farmInfo.phone)
            if let fax = farmInfo.fax {
                InfoRow(title: "Fax", value: fax)
            }
            if let email = farmInfo.email {
                InfoRow(title: "Email", value: email)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Owner Information Section
struct OwnerInformationSection: View {
    let ownerInfo: OwnerInformation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Owner Information")
                .font(.headline)
            
            InfoRow(title: "First Name", value: ownerInfo.firstName.isEmpty ? "null" : ownerInfo.firstName)
            InfoRow(title: "Last Name", value: ownerInfo.lastName.isEmpty ? "null" : ownerInfo.lastName)
            InfoRow(title: "ID Number", value: ownerInfo.idNumber.isEmpty ? "null" : ownerInfo.idNumber)
            InfoRow(title: "Address", value: ownerInfo.address.isEmpty ? "null" : ownerInfo.address)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Main Search Animal View
struct SearchAnimalView: View {
    @State private var searchID: String = ""
    @State private var animalData: NFCAnimalData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 25)
                
                // Search Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Search by Animal ID")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.darkGreen)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        TextField(
                            "",
                            text: $searchID,
                            prompt: Text("Enter Animal ID")
                                .foregroundColor(Color.black.opacity(0.4))
                                .font(.system(size: 17, weight: .semibold))
                        )
                        .keyboardType(.numberPad)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.darkGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.rust, lineWidth: 2)
                        )
                        Button(action: searchAnimal) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Theme.rust)
                                .cornerRadius(12)
                        }
                        .disabled(searchID.isEmpty || isLoading)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                if isLoading {
                    Spacer()
                        .frame(height: 100)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else if let animal = animalData {
                    VStack(spacing: 20) {
                        // Basic Information
                        InfoSection(title: "Basic Information") {
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "Animal Name", value: nullIfEmpty(animal.animalName))
                                InfoRow(title: "ID", value: animal.id)
                                InfoRow(title: "Gender", value: nullIfEmpty(animal.gender))
                                InfoRow(title: "Breed", value: nullIfEmpty(animal.breed))
                                InfoRow(title: "Birth Date", value: formatDate(animal.birthDate))
                                InfoRow(title: "Parent ID", value: nullIfEmpty(animal.parentId))
                                InfoRow(title: "Birth Farm ID", value: nullIfEmpty(animal.birthFarmId))
                                InfoRow(title: "Current Farm ID", value: nullIfEmpty(animal.currentFarmId))
                            }
                        }
                        
                        // Additional Information
                        InfoSection(title: "Additional Information") {
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "Transfer Date", value: animal.transferDate.map(formatDate) ?? "null")
                                InfoRow(title: "Export Country", value: nullIfEmpty(animal.exportCountry))
                                InfoRow(title: "Export Date", value: animal.exportDate.map(formatDate) ?? "null")
                                InfoRow(title: "Death Date", value: animal.deathDate.map(formatDate) ?? "null")
                                InfoRow(title: "Death Location", value: nullIfEmpty(animal.deathLocation))
                            }
                        }
                        
                        // Vaccinations
                        InfoSection(title: "Vaccination Information") {
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "SAP Vaccine", value: animal.vaccinations.sapVaccine.map(formatDate) ?? "null")
                                InfoRow(title: "Brucella Vaccine", value: animal.vaccinations.brucellaVaccine.map(formatDate) ?? "null")
                                InfoRow(title: "Pasteurella Vaccine", value: animal.vaccinations.pasteurellaVaccine.map(formatDate) ?? "null")
                                InfoRow(title: "Other Vaccine", value: animal.vaccinations.otherVaccine.map(formatDate) ?? "null")
                            }
                        }
                        
                        // Farm Information
                        InfoSection(title: "Farm Information") {
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "Country Code", value: nullIfEmpty(animal.farmInformation.countryCode))
                                InfoRow(title: "Province Code", value: nullIfEmpty(animal.farmInformation.provinceCode))
                                InfoRow(title: "Farm ID", value: nullIfEmpty(animal.farmInformation.farmId))
                                InfoRow(title: "Address", value: nullIfEmpty(animal.farmInformation.address))
                                InfoRow(title: "Coordinates", value: nullIfEmpty(animal.farmInformation.coordinates))
                                InfoRow(title: "Phone", value: nullIfEmpty(animal.farmInformation.phone))
                                InfoRow(title: "Fax", value: nullIfEmpty(animal.farmInformation.fax))
                                InfoRow(title: "Email", value: nullIfEmpty(animal.farmInformation.email))
                            }
                        }
                        
                        // Owner Information
                        InfoSection(title: "Owner Information") {
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "First Name", value: animal.ownerInformation.firstName.isEmpty ? "null" : animal.ownerInformation.firstName)
                                InfoRow(title: "Last Name", value: animal.ownerInformation.lastName.isEmpty ? "null" : animal.ownerInformation.lastName)
                                InfoRow(title: "ID Number", value: animal.ownerInformation.idNumber.isEmpty ? "null" : animal.ownerInformation.idNumber)
                                InfoRow(title: "Address", value: animal.ownerInformation.address.isEmpty ? "null" : animal.ownerInformation.address)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Show centered message when no search has been performed
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Theme.darkGreen)
                                .frame(width: 48, height: 48)
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                        }
                        Text("Enter your animal's ID above to access all information about your animal.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Theme.darkGreen)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.60)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Animal Search")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    private func searchAnimal() {
        guard !searchID.isEmpty else { return }
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoading = true
        errorMessage = nil
        animalData = nil
        
        FirebaseManager.shared.getAnimalData(by: searchID) { result in
            isLoading = false
            
            switch result {
            case .success(let animal):
                self.animalData = animal
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

// MARK: - Helper Views
struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.darkGreen)
                .padding(.bottom, 5)
            
            VStack(alignment: .leading) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.lightGreen, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Theme.brown)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.body)
                .foregroundColor(Theme.darkGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Helper Functions
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: date)
}

func nullIfEmpty(_ value: String?) -> String {
    if let v = value, !v.isEmpty { return v }
    return "null"
}

#Preview {
    SearchAnimalView()
} 