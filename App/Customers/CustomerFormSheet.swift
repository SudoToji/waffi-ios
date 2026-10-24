import SwiftUI

/// Add a Customer (`customer` nil) or edit one: the website's add and edit forms.
struct CustomerFormSheet: View {
    let customer: Customer?
    /// Saves the entries; the API's refusal, or nil when it worked.
    let submit: (CustomerForm) async -> ApiError?
    @State private var form: CustomerForm
    @State private var error: ApiError?
    @State private var saving = false
    @Environment(\.dismiss) private var dismiss

    init(customer: Customer?, submit: @escaping (CustomerForm) async -> ApiError?) {
        self.customer = customer
        self.submit = submit
        _form = State(initialValue: customer.map(CustomerForm.init) ?? CustomerForm())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $form.name)
                        .textContentType(.name)
                    TextField("Email", text: $form.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $form.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .environment(\.layoutDirection, .leftToRight)
                        .multilineTextAlignment(.leading)
                } footer: {
                    Text("At least an email or phone is required.")
                }
                Section {
                    Picker("Preferred language", selection: $form.locale) {
                        Text("English").tag("en")
                        Text("Arabic").tag("ar")
                    }
                    if customer != nil {
                        Toggle("Birthday", isOn: $form.hasBirthday)
                        if form.hasBirthday {
                            DatePicker(
                                "Birthday", selection: $form.birthday, in: Self.birthdays, displayedComponents: .date
                            )
                            .environment(\.calendar, Calendar(identifier: .gregorian))
                        }
                    }
                }
                if let customer { marketing(customer) }
                if let error {
                    Section {
                        Text(error.message).foregroundStyle(Theme.warning)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(submitTitle) { Task { await save() } }
                        .disabled(saving || form.trimmedName.isEmpty)
                }
            }
            .interactiveDismissDisabled(saving)
            .onChange(of: form) { error = nil }
        }
    }

    private var title: LocalizedStringKey { customer == nil ? "Add customer" : "Edit customer" }
    private var submitTitle: LocalizedStringKey { customer == nil ? "Add customer" : "Save changes" }

    /// 1900-01-01 up to today, as the website's date field.
    private static var birthdays: ClosedRange<Date> {
        let first = Calendar(identifier: .gregorian).date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? .distantPast
        return first...Date.now
    }

    @ViewBuilder private func marketing(_ customer: Customer) -> some View {
        Section {
            if customer.marketingConsent == true {
                Toggle(isOn: $form.stopMarketing) {
                    Text("\(customer.name) asked to stop marketing messages")
                }
            } else {
                Text("Has not agreed to marketing messages.").foregroundStyle(Theme.secondaryText)
            }
        } footer: {
            if customer.marketingConsent == true {
                Text("Only the customer can agree again, from their card page.")
            }
        }
    }

    private func save() async {
        if let problem = form.problem {
            error = ApiError(code: problem)
            return
        }
        saving = true
        defer { saving = false }
        error = await submit(form)
        if error == nil { dismiss() }
    }
}
