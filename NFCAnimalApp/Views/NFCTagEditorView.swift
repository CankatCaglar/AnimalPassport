import SwiftUI
import CoreNFC
import FirebaseAuth
import FirebaseFirestore

struct NFCTagEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingScannerAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingReadDataAlert = false
    @State private var readDataMessage = ""
    
    // NFC Reader and Writer instances
    private let nfcReader = NFCReader()
    private let nfcWriter = NFCWriter()
    
    // Animal Information
    @State private var animalId = ""
    @State private var animalName: String = ""
    @State private var birthDate = Date()
    @State private var gender = ""
    @State private var breed = ""
    @State private var parentId = ""
    @State private var birthFarmId = ""
    @State private var currentFarmId = ""
    @State private var transferDate = Date()
    @State private var exportCountry = ""
    @State private var exportDate = Date()
    @State private var deathDate = Date()
    @State private var deathLocation = ""
    
    // Vaccinations
    @State private var sapVaccine: Date? = nil
    @State private var brucellaVaccine: Date? = nil
    @State private var pasteurellaVaccine: Date? = nil
    @State private var otherVaccine: Date? = nil
    
    // Slaughterhouse Information
    @State private var slaughterhouseName = ""
    @State private var slaughterhouseAddress = ""
    @State private var slaughterhouseLicenseNo = ""
    @State private var slaughterDate = Date()
    
    // Farm Information
    @State private var countryCode = ""
    @State private var provinceCode = ""
    @State private var farmId = ""
    @State private var farmAddress = ""
    @State private var farmCoordinates = ""
    @State private var farmPhone = ""
    @State private var farmFax = ""
    @State private var farmEmail = ""
    
    // Owner Information
    @State private var ownerFirstName = ""
    @State private var ownerLastName = ""
    @State private var ownerIdNumber = ""
    @State private var ownerAddress = ""
    
    @State private var userType: String = ""
    @State private var showAnimalForm = false
    @State private var showReadData = false
    
    private var nfcAnimalData: NFCAnimalData {
        NFCAnimalData(
            id: animalId,
            animalName: animalName,
            birthDate: birthDate,
            gender: gender,
            breed: breed,
            parentId: parentId,
            birthFarmId: birthFarmId,
            currentFarmId: currentFarmId,
            transferDate: transferDate,
            exportCountry: exportCountry,
            exportDate: exportDate,
            deathDate: deathDate,
            deathLocation: deathLocation,
            vaccinations: Vaccinations(
                sapVaccine: sapVaccine,
                brucellaVaccine: brucellaVaccine,
                pasteurellaVaccine: pasteurellaVaccine,
                otherVaccine: otherVaccine
            ),
            slaughterhouse: Slaughterhouse(
                name: slaughterhouseName,
                address: slaughterhouseAddress,
                licenseNumber: slaughterhouseLicenseNo,
                slaughterDate: slaughterDate
            ),
            farmInformation: FarmInformation(
                countryCode: countryCode,
                provinceCode: provinceCode,
                farmId: farmId,
                address: farmAddress,
                coordinates: farmCoordinates,
                phone: farmPhone,
                fax: farmFax,
                email: farmEmail
            ),
            ownerInformation: OwnerInformation(
                firstName: ownerFirstName,
                lastName: ownerLastName,
                idNumber: ownerIdNumber,
                address: ownerAddress
            )
        )
    }
    
    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 25)
                    Text("What do you want to do?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.darkGreen)
                        .padding(.bottom, 20)
                    if userType.lowercased() == "veterinarian" {
                        VStack(spacing: 20) {
                            Button(action: readFromNFCTag) {
                                VStack(spacing: 8) {
                                    Image(systemName: "wave.3.right.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.rust)
                                    Text("Read Tag")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.rust)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            }
                            Button(action: { showAnimalForm.toggle() }) {
                                HStack(spacing: 10) {
                                    Image(systemName: showAnimalForm ? "minus.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.rust)
                                    Text(showAnimalForm ? "Hide Animal Form" : "Add Animal")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.rust)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            }
                            if showAnimalForm {
                                VStack(alignment: .leading, spacing: 25) {
                                    sectionTitle("Animal Information")
                                    animalInfoSection
                                    sectionTitle("Vaccinations")
                                    vaccinationSection
                                    sectionTitle("Slaughterhouse Information")
                                    slaughterhouseSection
                                    sectionTitle("Farm Information")
                                    farmInfoSection
                                    sectionTitle("Owner Information")
                                    ownerInfoSection
                                    Button(action: writeToNFCTag) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "wave.3.right.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                            Text("Write Tag")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Theme.rust)
                                        .cornerRadius(12)
                                    }
                                    .padding(.top, 16)
                                    .padding(.bottom, 32)
                                }
                                .padding(.top, 20)
                            }
                        }
                        .padding(.horizontal)
                    } else if userType.lowercased() == "pet-owner" {
                        VStack(spacing: 20) {
                            Button(action: { readFromNFCTag(); showReadData = false }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "wave.3.right.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.rust)
                                    Text("Read Tag")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.rust)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            }
                            if showReadData {
                                VStack(alignment: .leading, spacing: 25) {
                                    sectionTitle("Animal Information")
                                    animalInfoSection
                                    sectionTitle("Vaccinations")
                                    vaccinationSection
                                    sectionTitle("Slaughterhouse Information")
                                    slaughterhouseSection
                                    sectionTitle("Farm Information")
                                    farmInfoSection
                                    sectionTitle("Owner Information")
                                    ownerInfoSection
                                }
                                .padding(.top, 20)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit NFC Tag")
                    .font(.headline)
                    .foregroundColor(Theme.darkGreen)
            }
        }
        .alert("NFC Scanner", isPresented: $showingScannerAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("NFC scanning functionality will be implemented here.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { showReadData = true }
        } message: {
            Text(successMessage)
        }
        .alert("Read Data", isPresented: $showingReadDataAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(readDataMessage)
        }
        .onAppear {
            // Kullanıcı tipini Firestore'dan çek
            if let user = Auth.auth().currentUser {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).getDocument { document, error in
                    if let data = document?.data(), let type = data["userType"] as? String {
                        userType = type
                    }
                }
            }
        }
    }
    
    private func readFromNFCTag() {
        nfcReader.readFromTag { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let animalData):
                    // Update all the fields with the read data
                    self.animalId = animalData.id
                    self.animalName = animalData.animalName ?? ""
                    self.birthDate = animalData.birthDate
                    self.gender = animalData.gender
                    self.breed = animalData.breed
                    self.parentId = animalData.parentId ?? ""
                    self.birthFarmId = animalData.birthFarmId
                    self.currentFarmId = animalData.currentFarmId
                    self.transferDate = animalData.transferDate ?? Date()
                    self.exportCountry = animalData.exportCountry ?? ""
                    self.exportDate = animalData.exportDate ?? Date()
                    self.deathDate = animalData.deathDate ?? Date()
                    self.deathLocation = animalData.deathLocation ?? ""
                    
                    // Vaccinations
                    self.sapVaccine = animalData.vaccinations.sapVaccine
                    self.brucellaVaccine = animalData.vaccinations.brucellaVaccine
                    self.pasteurellaVaccine = animalData.vaccinations.pasteurellaVaccine
                    self.otherVaccine = animalData.vaccinations.otherVaccine
                    
                    // Slaughterhouse
                    if let slaughterhouse = animalData.slaughterhouse {
                        self.slaughterhouseName = slaughterhouse.name
                        self.slaughterhouseAddress = slaughterhouse.address
                        self.slaughterhouseLicenseNo = slaughterhouse.licenseNumber
                        self.slaughterDate = slaughterhouse.slaughterDate
                    }
                    
                    // Farm Information
                    self.countryCode = animalData.farmInformation.countryCode
                    self.provinceCode = animalData.farmInformation.provinceCode
                    self.farmId = animalData.farmInformation.farmId
                    self.farmAddress = animalData.farmInformation.address
                    self.farmCoordinates = animalData.farmInformation.coordinates
                    self.farmPhone = animalData.farmInformation.phone
                    self.farmFax = animalData.farmInformation.fax ?? ""
                    self.farmEmail = animalData.farmInformation.email ?? ""
                    
                    // Owner Information
                    self.ownerFirstName = animalData.ownerInformation.firstName
                    self.ownerLastName = animalData.ownerInformation.lastName
                    self.ownerIdNumber = animalData.ownerInformation.idNumber
                    self.ownerAddress = animalData.ownerInformation.address
                    
                    // Okuma başarılıysa, kullanıcı tipi ne olursa olsun bilgileri göster
                    showReadData = true
                    // Veterinarian ise Add Animal formu da otomatik açılsın
                    if userType.lowercased() == "veterinarian" {
                        showAnimalForm = true
                    }
                case .failure(let error):
                    errorMessage = "Failed to read NFC tag: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func writeToNFCTag() {
        if OfflineManager.shared.isInternetAvailable() {
            // Internet is available, try to save to Firebase first
            FirebaseManager.shared.saveAnimalData(nfcAnimalData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let id):
                        // Firebase save successful, now write to NFC tag
                        self.nfcWriter.writeToTag(animalData: self.nfcAnimalData) { success, message in
                            DispatchQueue.main.async {
                                if success {
                                    self.successMessage = "Data successfully saved! ID: \(id)"
                                    self.showingSuccessAlert = true
                                } else {
                                    self.errorMessage = "Saved to Firebase but failed to write to NFC tag: \(message)"
                                    self.showingError = true
                                }
                            }
                        }
                    case .failure(let error):
                        // Firebase save failed, stop the process
                        self.errorMessage = "Failed to save to Firebase: \(error.localizedDescription)"
                        self.showingError = true
                    }
                }
            }
        } else {
            // No internet, write directly to NFC tag
            self.nfcWriter.writeToTag(animalData: self.nfcAnimalData) { success, message in
                DispatchQueue.main.async {
                    if success {
                        self.successMessage = "Successfully written to tag! Data will be synced when internet is available."
                        self.showingSuccessAlert = true
                    } else {
                        self.errorMessage = "Failed to write to NFC tag: \(message)"
                        self.showingError = true
                    }
                }
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(Theme.darkGreen)
            .padding(.top)
    }
    
    private var animalInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            EditorTextField(text: $animalId, label: "Animal ID")
            EditorTextField(text: $animalName, label: "Animal Name")
            DateField(date: $birthDate, label: "Birth Date")
                .padding(.horizontal, 0)
            EditorTextField(text: $gender, label: "Gender")
            EditorTextField(text: $breed, label: "Breed")
            EditorTextField(text: $parentId, label: "Parent ID")
            EditorTextField(text: $birthFarmId, label: "Birth Farm ID")
            EditorTextField(text: $currentFarmId, label: "Current Farm ID")
            // Additional Information
            sectionTitle("Additional Information")
            DateField(date: $deathDate, label: "Death Date")
                .padding(.horizontal, 0)
            EditorTextField(text: $deathLocation, label: "Death Location")
            EditorTextField(text: $exportCountry, label: "Export Country")
        }
    }
    
    private var vaccinationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text("SAP Vaccine")
                    .foregroundColor(Theme.darkGreen)
                    .font(.subheadline)
                HStack {
                    if let date = sapVaccine {
                        DatePicker("", selection: Binding(
                            get: { date },
                            set: { sapVaccine = $0 }
                        ), displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .accentColor(Theme.rust)
                        .foregroundColor(Theme.darkGreen)
                        .environment(\.colorScheme, .light)
                        
                        Button(action: { sapVaccine = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.rust)
                        }
                    } else {
                        Button(action: { sapVaccine = Date() }) {
                            Text("Select Date")
                                .foregroundColor(Theme.darkGreen)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Brucella Vaccine")
                    .foregroundColor(Theme.darkGreen)
                    .font(.subheadline)
                HStack {
                    if let date = brucellaVaccine {
                        DatePicker("", selection: Binding(
                            get: { date },
                            set: { brucellaVaccine = $0 }
                        ), displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .accentColor(Theme.rust)
                        .foregroundColor(Theme.darkGreen)
                        .environment(\.colorScheme, .light)
                        
                        Button(action: { brucellaVaccine = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.rust)
                        }
                    } else {
                        Button(action: { brucellaVaccine = Date() }) {
                            Text("Select Date")
                                .foregroundColor(Theme.darkGreen)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Pasteurella Vaccine")
                    .foregroundColor(Theme.darkGreen)
                    .font(.subheadline)
                HStack {
                    if let date = pasteurellaVaccine {
                        DatePicker("", selection: Binding(
                            get: { date },
                            set: { pasteurellaVaccine = $0 }
                        ), displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .accentColor(Theme.rust)
                        .foregroundColor(Theme.darkGreen)
                        .environment(\.colorScheme, .light)
                        
                        Button(action: { pasteurellaVaccine = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.rust)
                        }
                    } else {
                        Button(action: { pasteurellaVaccine = Date() }) {
                            Text("Select Date")
                                .foregroundColor(Theme.darkGreen)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Other Vaccine")
                    .foregroundColor(Theme.darkGreen)
                    .font(.subheadline)
                HStack {
                    if let date = otherVaccine {
                        DatePicker("", selection: Binding(
                            get: { date },
                            set: { otherVaccine = $0 }
                        ), displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .accentColor(Theme.rust)
                        .foregroundColor(Theme.darkGreen)
                        .environment(\.colorScheme, .light)
                        
                        Button(action: { otherVaccine = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.rust)
                        }
                    } else {
                        Button(action: { otherVaccine = Date() }) {
                            Text("Select Date")
                                .foregroundColor(Theme.darkGreen)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.lightGreen, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
    
    private var slaughterhouseSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            EditorTextField(text: $slaughterhouseName, label: "Name")
            EditorTextField(text: $slaughterhouseAddress, label: "Address")
            EditorTextField(text: $slaughterhouseLicenseNo, label: "License Number")
            DateField(date: $slaughterDate, label: "Slaughter Date")
                .padding(.horizontal, 0)
        }
    }
    
    private var farmInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            EditorTextField(text: $countryCode, label: "Country Code")
            EditorTextField(text: $provinceCode, label: "Province Code")
            EditorTextField(text: $farmId, label: "Farm ID")
            EditorTextField(text: $farmAddress, label: "Farm Address")
            EditorTextField(text: $farmCoordinates, label: "Coordinates")
            EditorTextField(text: $farmPhone, label: "Phone")
            EditorTextField(text: $farmFax, label: "Fax")
            EditorTextField(text: $farmEmail, label: "Email")
        }
    }
    
    private var ownerInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            EditorTextField(text: $ownerFirstName, label: "First Name")
            EditorTextField(text: $ownerLastName, label: "Last Name")
            EditorTextField(text: $ownerIdNumber, label: "ID Number")
            EditorTextField(text: $ownerAddress, label: "Address")
        }
    }
}

struct EditorTextField: View {
    @Binding var text: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .foregroundColor(Theme.darkGreen)
                .font(.subheadline)
            TextField("", text: $text)
                .foregroundColor(Theme.darkGreen)
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.lightGreen, lineWidth: 1)
                )
        }
    }
}

struct DateField: View {
    @Binding var date: Date
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .foregroundColor(Theme.darkGreen)
                .font(.subheadline)
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .accentColor(Theme.rust)
                .foregroundColor(Theme.darkGreen)
                .environment(\.colorScheme, .light)
        }
    }
} 