import SwiftUI

/// The message: its language, title and text, and the optional translation for Customers who read the other language.
struct MessageSection: View {
    @Bindable var model: ComposerModel

    private var direction: LayoutDirection { model.form.locale == "ar" ? .rightToLeft : .leftToRight }
    private var otherDirection: LayoutDirection { model.form.otherLocale == "ar" ? .rightToLeft : .leftToRight }

    var body: some View {
        ComposerCard {
            HStack {
                Text("Message").font(.headline).foregroundStyle(Theme.text).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Picker("Message language", selection: $model.form.locale) {
                    Text(verbatim: "EN").tag("en")
                    Text(verbatim: "عربي").tag("ar")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
            }
            fields(title: $model.form.title, body: $model.form.body, direction: direction)
            Toggle(isOn: $model.form.translating) {
                Text("Also write it in \(language(model.form.otherLocale))")
            }
            .tint(Theme.accent)
            if model.form.translating {
                Text("Customers whose language is \(language(model.form.otherLocale)) get this version. Everyone else gets the main message.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                fields(title: $model.form.translationTitle, body: $model.form.translationBody, direction: otherDirection)
            }
        }
    }

    private func language(_ locale: String) -> String {
        locale == "ar" ? String(localized: "Arabic") : String(localized: "English")
    }

    private func fields(title: Binding<String>, body: Binding<String>, direction: LayoutDirection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Message title", text: title)
                .waffiField()
                .onChange(of: title.wrappedValue) { if title.wrappedValue.count > 50 { title.wrappedValue = String(title.wrappedValue.prefix(50)) } }
            FieldCaption(text: Text("\(title.wrappedValue.count)/50"))
            TextField("Message", text: body, axis: .vertical)
                .lineLimit(3...8)
                .padding(14)
                .foregroundStyle(Theme.text)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
                .onChange(of: body.wrappedValue) { if body.wrappedValue.count > 240 { body.wrappedValue = String(body.wrappedValue.prefix(240)) } }
            HStack {
                FieldCaption(text: Text("Shown on the Customer's pass"))
                Spacer()
                FieldCaption(text: Text("\(body.wrappedValue.count)/240"))
            }
        }
        .environment(\.layoutDirection, direction)
    }
}
