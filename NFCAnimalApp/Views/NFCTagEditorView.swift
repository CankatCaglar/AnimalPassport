import SwiftUI
import CoreNFC
import FirebaseAuth
import FirebaseFirestore

struct NFCTagEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var activitiesViewModel = ActivitiesViewModel()
    @State private var showingScannerAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingReadDataAlert = false
    @State private var readDataMessage = ""
    @State private var recentActivities: [Activity] = []
    
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
    @State private var deathDate: Date? = nil
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
    @State private var showGenderSheet = false
    
    @State private var statTotalTags: Int = 0
    @State private var statActiveTags: Int = 0
    @State private var statThisMonth: Int = 0
    @State private var statsListener: ListenerRegistration? = nil
    
    // Add validation state variables
    @State private var validationErrors: [String: String] = [:]
    @State private var showingValidationError = false
    
    let genderOptions = ["Male", "Female"]
    
    private func clearAllFields() {
        animalId = ""
        animalName = ""
        birthDate = Date()
        gender = ""
        breed = ""
        parentId = ""
        birthFarmId = ""
        currentFarmId = ""
        transferDate = Date()
        exportCountry = ""
        exportDate = Date()
        deathDate = nil
        deathLocation = ""
        
        // Vaccinations
        sapVaccine = nil
        brucellaVaccine = nil
        pasteurellaVaccine = nil
        otherVaccine = nil
        
        // Slaughterhouse Information
        slaughterhouseName = ""
        slaughterhouseAddress = ""
        slaughterhouseLicenseNo = ""
        slaughterDate = Date()
        
        // Farm Information
        countryCode = ""
        provinceCode = ""
        farmId = ""
        farmAddress = ""
        farmCoordinates = ""
        farmPhone = ""
        farmFax = ""
        farmEmail = ""
        
        // Owner Information
        ownerFirstName = ""
        ownerLastName = ""
        ownerIdNumber = ""
        ownerAddress = ""
    }
    
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
    
    private func fetchStatistics() {
        FirebaseManager.shared.fetchAnimalStatistics { total, active, thisMonth in
            statTotalTags = total
            statActiveTags = active
            statThisMonth = thisMonth
        }
    }
    
    // Add validation functions
    private func validateAnimalId() -> Bool {
        if animalId.isEmpty {
            validationErrors["animalId"] = "Animal ID is required"
            return false
        }
        if !animalId.isNumeric {
            validationErrors["animalId"] = "Animal ID must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "animalId")
        return true
    }
    
    private func validateAnimalName() -> Bool {
        if animalName.isEmpty {
            validationErrors["animalName"] = "Animal Name is required"
            return false
        }
        if !animalName.isAlphabeticWithSpaces {
            validationErrors["animalName"] = "Animal Name must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "animalName")
        return true
    }
    
    private func validateBirthDate() -> Bool {
        // Birth date is always valid as it's a Date object with a default value
        return true
    }
    
    private func validateGender() -> Bool {
        if gender.isEmpty {
            validationErrors["gender"] = "Gender is required"
            return false
        }
        validationErrors.removeValue(forKey: "gender")
        return true
    }
    
    private func validateBreed() -> Bool {
        if breed.isEmpty {
            validationErrors["breed"] = "Breed is required"
            return false
        }
        if !breed.isAlphabeticWithSpaces {
            validationErrors["breed"] = "Breed must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "breed")
        return true
    }
    
    private func validateParentId() -> Bool {
        if parentId.isEmpty {
            validationErrors["parentId"] = "Parent ID is required"
            return false
        }
        if !parentId.isNumeric {
            validationErrors["parentId"] = "Parent ID must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "parentId")
        return true
    }
    
    private func validateBirthFarmId() -> Bool {
        if birthFarmId.isEmpty {
            validationErrors["birthFarmId"] = "Birth Farm ID is required"
            return false
        }
        if !birthFarmId.isNumeric {
            validationErrors["birthFarmId"] = "Birth Farm ID must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "birthFarmId")
        return true
    }
    
    private func validateCurrentFarmId() -> Bool {
        if currentFarmId.isEmpty {
            validationErrors["currentFarmId"] = "Current Farm ID is required"
            return false
        }
        if !currentFarmId.isNumeric {
            validationErrors["currentFarmId"] = "Current Farm ID must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "currentFarmId")
        return true
    }
    
    private func validateOwnerFirstName() -> Bool {
        if ownerFirstName.isEmpty {
            validationErrors["ownerFirstName"] = "Owner First Name is required"
            return false
        }
        if !ownerFirstName.isAlphabeticWithSpaces {
            validationErrors["ownerFirstName"] = "Owner First Name must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "ownerFirstName")
        return true
    }
    
    private func validateOwnerLastName() -> Bool {
        if ownerLastName.isEmpty {
            validationErrors["ownerLastName"] = "Owner Last Name is required"
            return false
        }
        if !ownerLastName.isAlphabeticWithSpaces {
            validationErrors["ownerLastName"] = "Owner Last Name must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "ownerLastName")
        return true
    }
    
    private func validateOwnerIdNumber() -> Bool {
        if ownerIdNumber.isEmpty {
            validationErrors["ownerIdNumber"] = "Owner ID Number is required"
            return false
        }
        if !ownerIdNumber.isNumeric {
            validationErrors["ownerIdNumber"] = "Owner ID Number must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "ownerIdNumber")
        return true
    }
    
    private func validateDeathLocation() -> Bool {
        if !deathLocation.isEmpty && !deathLocation.isAlphabeticWithSpaces {
            validationErrors["deathLocation"] = "Death Location must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "deathLocation")
        return true
    }
    
    private func validateExportCountry() -> Bool {
        if !exportCountry.isEmpty && !exportCountry.isAlphabeticWithSpaces {
            validationErrors["exportCountry"] = "Export Country must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "exportCountry")
        return true
    }
    
    private func validateSlaughterhouseName() -> Bool {
        if !slaughterhouseName.isEmpty && !slaughterhouseName.isAlphabeticWithSpaces {
            validationErrors["slaughterhouseName"] = "Slaughterhouse Name must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "slaughterhouseName")
        return true
    }
    
    private func validateSlaughterhouseAddress() -> Bool {
        if !slaughterhouseAddress.isEmpty && !slaughterhouseAddress.isAlphabeticWithSpaces {
            validationErrors["slaughterhouseAddress"] = "Slaughterhouse Address must contain only letters and spaces"
            return false
        }
        validationErrors.removeValue(forKey: "slaughterhouseAddress")
        return true
    }
    
    private func validateSlaughterhouseLicenseNo() -> Bool {
        if !slaughterhouseLicenseNo.isEmpty && !slaughterhouseLicenseNo.isNumeric {
            validationErrors["slaughterhouseLicenseNo"] = "License Number must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "slaughterhouseLicenseNo")
        return true
    }
    
    private func validateFarmPhone() -> Bool {
        if !farmPhone.isEmpty && !farmPhone.isNumeric {
            validationErrors["farmPhone"] = "Phone must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "farmPhone")
        return true
    }
    
    private func validateFarmFax() -> Bool {
        if !farmFax.isEmpty && !farmFax.isNumeric {
            validationErrors["farmFax"] = "Fax must be numeric"
            return false
        }
        validationErrors.removeValue(forKey: "farmFax")
        return true
    }
    
    private func validateFarmEmail() -> Bool {
        if !farmEmail.isEmpty && !farmEmail.isValidEmail {
            validationErrors["farmEmail"] = "Invalid email format"
            return false
        }
        validationErrors.removeValue(forKey: "farmEmail")
        return true
    }
    
    private func validateAll() -> Bool {
        let validations = [
            validateAnimalId(),
            validateAnimalName(),
            validateBirthDate(),
            validateGender(),
            validateBreed(),
            validateParentId(),
            validateBirthFarmId(),
            validateCurrentFarmId(),
            validateOwnerFirstName(),
            validateOwnerLastName(),
            validateOwnerIdNumber(),
            // Optional field validations
            validateDeathLocation(),
            validateExportCountry(),
            validateSlaughterhouseName(),
            validateSlaughterhouseAddress(),
            validateSlaughterhouseLicenseNo(),
            validateFarmPhone(),
            validateFarmFax(),
            validateFarmEmail()
        ]
        
        return validations.allSatisfy { $0 }
    }
    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        return validateAll()
    }
    
    // Update the write button in the view
    private var writeButton: some View {
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
            .background(isFormValid ? Theme.rust : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isFormValid)
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
                    
                    // Main Action Buttons
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
                            Button(action: {
                                if showAnimalForm {
                                    clearAllFields()
                                }
                                showAnimalForm.toggle()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: showAnimalForm ? "minus.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.rust)
                                    Text(showAnimalForm ? "Hide Animal Form" : "Add/Edit Animal")
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
                                    writeButton
                                }
                                .padding(.top, 20)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Recent Activities Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Activities")
                                .font(.headline)
                                .foregroundColor(Theme.darkGreen)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    if activitiesViewModel.activities.isEmpty {
                                        VStack(spacing: 8) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 32))
                                                .foregroundColor(Theme.rust)
                                            Text("No recent activities")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(Theme.darkGreen)
                                        }
                                        .frame(width: 200, height: 100)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.lightGreen, lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    } else {
                                        ForEach(activitiesViewModel.activities) { activity in
                                            ActivityCard(
                                                icon: iconForActivityType(activity.type),
                                                title: activity.type.rawValue,
                                                description: "Animal ID: \(activity.animalId)",
                                                time: activity.timeAgo
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 30)
                        
                        // Statistics Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Statistics")
                                .font(.headline)
                                .foregroundColor(Theme.darkGreen)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                StatCard(
                                    icon: "tag.fill",
                                    title: "Total Tags",
                                    value: String(statTotalTags)
                                )
                                StatCard(
                                    icon: "checkmark.circle.fill",
                                    title: "Active Tags",
                                    value: String(statActiveTags)
                                )
                                StatCard(
                                    icon: "clock.fill",
                                    title: "This Month",
                                    value: String(statThisMonth)
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
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
            .refreshable {
                fetchStatistics()
            }
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit NFC Tag")
                    .font(.headline)
                    .foregroundColor(.white)
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
        .alert("Validation Error", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationErrors.values.joined(separator: "\n"))
        }
        .onAppear {
            // Activities will be automatically loaded by the ViewModel
            // Kullanıcı tipini Firestore'dan çek
            if let user = Auth.auth().currentUser {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).getDocument { document, error in
                    if let data = document?.data(), let type = data["userType"] as? String {
                        userType = type
                    }
                }
            }
            // Firestore snapshot listener ile istatistikleri canlı güncelle
            statsListener?.remove()
            statsListener = Firestore.firestore().collection("animals").addSnapshotListener { _, _ in
                fetchStatistics()
            }
            fetchStatistics()
        }
        .onDisappear {
            statsListener?.remove()
            statsListener = nil
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                    
                    // Log the read activity
                    Activity.logActivity(type: .readTag, animalId: animalData.id)
                    
                    // Refresh activities
                    activitiesViewModel.refresh()
                    
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
        if !validateAll() {
            showingValidationError = true
            return
        }
        
        if OfflineManager.shared.isInternetAvailable() {
            // Internet is available, try to save to Firebase first
            FirebaseManager.shared.saveAnimalData(nfcAnimalData) { result in
                DispatchQueue.main.async {
                    fetchStatistics()
                    switch result {
                    case .success(let id):
                        // Firebase save successful, now write to NFC tag
                        self.nfcWriter.writeToTag(animalData: self.nfcAnimalData) { success, message in
                            DispatchQueue.main.async {
                                if success {
                                    // Log the write activity
                                    Activity.logActivity(type: .writeTag, animalId: self.animalId)
                                    
                                    // Refresh activities
                                    self.activitiesViewModel.refresh()
                                    
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
                        // Log the write activity
                        Activity.logActivity(type: .writeTag, animalId: self.animalId)
                        
                        // Refresh activities
                        self.activitiesViewModel.refresh()
                        
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
            EditorTextField(
                text: $animalId,
                label: "Animal ID *",
                keyboardType: .numberPad,
                error: validationErrors["animalId"]
            )
            EditorTextField(
                text: $animalName,
                label: "Animal Name *",
                keyboardType: .default,
                error: validationErrors["animalName"]
            )
            DateField(date: $birthDate, label: "Birth Date *")
                .padding(.horizontal, 0)
            // Gender Selector
            VStack(alignment: .leading, spacing: 5) {
                Text("Gender *")
                    .foregroundColor(Theme.darkGreen)
                    .font(.subheadline)
                Button(action: { showGenderSheet = true }) {
                    HStack {
                        Text(gender.isEmpty ? "Select Gender" : gender)
                            .foregroundColor(gender.isEmpty ? .gray : Theme.darkGreen)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(validationErrors["gender"] != nil ? Color.red : Theme.lightGreen, lineWidth: 1)
                    )
                }
            .actionSheet(isPresented: $showGenderSheet) {
                                        ActionSheet(title: Text("Select Gender"), buttons: [
                                            .default(Text("Male")) { gender = "Male" },
                                            .default(Text("Female")) { gender = "Female" },
                                            .cancel()
                                        ])
                                    }
                if let error = validationErrors["gender"] {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            EditorTextField(
                text: $breed,
                label: "Breed *",
                keyboardType: .default,
                error: validationErrors["breed"]
            )
            EditorTextField(
                text: $parentId,
                label: "Parent ID *",
                keyboardType: .numberPad,
                error: validationErrors["parentId"]
            )
            EditorTextField(
                text: $birthFarmId,
                label: "Birth Farm ID *",
                keyboardType: .numberPad,
                error: validationErrors["birthFarmId"]
            )
            EditorTextField(
                text: $currentFarmId,
                label: "Current Farm ID *",
                keyboardType: .numberPad,
                error: validationErrors["currentFarmId"]
            )
            // Additional Information
            sectionTitle("Additional Information")
            VStack(alignment: .leading, spacing: 5) {
                Text("Death Date")
                    .foregroundColor(Theme.darkGreen)
                    .font(.subheadline)
                if let date = deathDate {
                    HStack {
                        DatePicker("", selection: Binding(get: { date }, set: { deathDate = $0 }), displayedComponents: [.date])
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .accentColor(Theme.rust)
                            .foregroundColor(Theme.darkGreen)
                            .environment(\.colorScheme, .light)
                        Button(action: { deathDate = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.rust)
                        }
                    }
                } else {
                    Button(action: { deathDate = Date() }) {
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
            EditorTextField(text: $slaughterhouseLicenseNo, label: "License Number", keyboardType: .numberPad)
            DateField(date: $slaughterDate, label: "Slaughter Date")
                .padding(.horizontal, 0)
        }
    }
    
    private var farmInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            EditorTextField(text: $countryCode, label: "Country Code")
            EditorTextField(text: $provinceCode, label: "Province Code")
            EditorTextField(text: $farmId, label: "Farm ID", keyboardType: .numberPad)
            EditorTextField(text: $farmAddress, label: "Farm Address")
            EditorTextField(text: $farmCoordinates, label: "Coordinates")
            EditorTextField(text: $farmPhone, label: "Phone", keyboardType: .numberPad)
            EditorTextField(text: $farmFax, label: "Fax", keyboardType: .numberPad)
            EditorTextField(text: $farmEmail, label: "Email")
        }
    }
    
    private var ownerInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            EditorTextField(
                text: $ownerFirstName,
                label: "First Name *",
                keyboardType: .default,
                error: validationErrors["ownerFirstName"]
            )
            EditorTextField(
                text: $ownerLastName,
                label: "Last Name *",
                keyboardType: .default,
                error: validationErrors["ownerLastName"]
            )
            EditorTextField(
                text: $ownerIdNumber,
                label: "ID Number *",
                keyboardType: .numberPad,
                error: validationErrors["ownerIdNumber"]
            )
            EditorTextField(
                text: $ownerAddress,
                label: "Address",
                keyboardType: .default,
                error: validationErrors["ownerAddress"]
            )
        }
    }
    
    private func iconForActivityType(_ type: Activity.ActivityType) -> String {
        switch type {
        case .readTag:
            return "wave.3.right.circle.fill"
        case .writeTag:
            return "wave.3.right.circle.fill"
        case .addAnimal:
            return "plus.circle.fill"
        case .updateAnimal:
            return "pencil.circle.fill"
        }
    }
}

struct EditorTextField: View {
    @Binding var text: String
    let label: String
    var keyboardType: UIKeyboardType = .default
    var error: String?
    
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
                        .stroke(error != nil ? Color.red : Theme.lightGreen, lineWidth: 1)
                )
                .keyboardType(keyboardType)
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
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

// MARK: - Supporting Views
struct ActivityCard: View {
    let icon: String
    let title: String
    let description: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.rust)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.darkGreen)
            }
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(Theme.darkGreen.opacity(0.8))
            
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(Theme.darkGreen.opacity(0.6))
        }
        .padding()
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.rust)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.darkGreen)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.darkGreen.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Add String extensions for validation
extension String {
    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var isAlphabeticWithSpaces: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.letters.union(CharacterSet.whitespaces).inverted) == nil
    }
    
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
