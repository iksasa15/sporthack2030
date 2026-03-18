import SwiftUI

struct ProfileView: View {
    @AppStorage(AppThemePalette.storageKey) private var selectedPaletteRaw = AppThemePalette.defaultPalette.rawValue
    @AppStorage(AppConnection.hostKey) private var backendHost = AppConnection.defaultHost
    @AppStorage(AppConnection.useHTTPSKey) private var backendUseHTTPS = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var hostInput = ""
    @State private var isTestingConnection = false
    @State private var connectionMessage: String?
    @State private var connectionSucceeded = false

    private var selectedPalette: AppThemePalette {
        AppThemePalette(rawValue: selectedPaletteRaw) ?? AppThemePalette.defaultPalette
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    connectionSection
                    themeSection
                    ForEach(AppThemePalette.allCases) { palette in
                        paletteRow(for: palette)
                    }
                }
                .padding()
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("الملف الشخصي")
            .onAppear {
                hostInput = backendHost
            }
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("اتصال السيرفر")
                .font(.appFont(.medium, size: 18))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text("محلياً: IP:PORT مثل 192.168.1.10:5001. لصديق بمدينة ثانية: استخدم ngrok وضع العنوان بدون https، وفعّل «HTTPS» أدناه.")
                .font(.appFont(.regular, size: 13))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.7))

            Toggle(isOn: $backendUseHTTPS) {
                Text("HTTPS (ngrok / رابط عام)")
                    .font(.appFont(.regular, size: 15))
            }
            .tint(AppTheme.interactive(for: colorScheme))

            TextField("مثال: 192.168.1.5:5001 أو xxx.ngrok-free.app", text: $hostInput)
                .font(.appFont(.regular, size: 15))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.numbersAndPunctuation)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.background(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
                )

            HStack(spacing: 10) {
                Button {
                    Task { await testConnection(host: AppConnection.normalizedHost(hostInput)) }
                } label: {
                    HStack(spacing: 6) {
                        if isTestingConnection {
                            ProgressView()
                                .tint(AppTheme.primaryText(for: colorScheme))
                                .scaleEffect(0.85)
                        }
                        Text(isTestingConnection ? "جاري التحقق..." : "اختبار")
                            .font(.appFont(.medium, size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .background(AppTheme.card(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isTestingConnection)

                Button {
                    backendHost = AppConnection.normalizedHost(hostInput)
                    hostInput = backendHost
                    Task { await testConnection(host: backendHost) }
                } label: {
                    Text("حفظ")
                        .font(.appFont(.medium, size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(AppTheme.interactive(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isTestingConnection)
            }

            Text("الرابط الحالي: \(AppConnection.useHTTPS ? "https" : "http")://\(AppConnection.normalizedHost(backendHost))")
                .font(.appFont(.regular, size: 12))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.68))

            if let connectionMessage {
                Text(connectionMessage)
                    .font(.appFont(.regular, size: 13))
                    .foregroundStyle(connectionSucceeded ? .green : AppTheme.preventionAlert(for: colorScheme))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.card(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("تغيير الوان التطبيق")
                .font(.appFont(.medium, size: 18))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text("اختر مجموعة الألوان المناسبة لك، ويمكنك التبديل بينها في أي وقت.")
                .font(.appFont(.regular, size: 14))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.card(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private func paletteRow(for palette: AppThemePalette) -> some View {
        let isSelected = palette == selectedPalette
        let previewColors = palette.colors(for: colorScheme)

        return Button {
            selectedPaletteRaw = palette.rawValue
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(palette.title)
                        .font(.appFont(.medium, size: 15))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Text(palette.subtitle)
                        .font(.appFont(.regular, size: 13))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.7))
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle().fill(previewColors.background).frame(width: 14, height: 14)
                    Circle().fill(previewColors.card).frame(width: 14, height: 14)
                    Circle().fill(previewColors.interactive).frame(width: 14, height: 14)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.interactive(for: colorScheme) : AppTheme.cardBorder(for: colorScheme))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.interactive(for: colorScheme) : AppTheme.cardBorder(for: colorScheme),
                        lineWidth: isSelected ? 1.2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func testConnection(host: String? = nil) async {
        isTestingConnection = true
        defer { isTestingConnection = false }

        let hostToTest = host ?? backendHost
        let urlString = AppConnection.healthURLString(for: hostToTest)
        guard let url = URL(string: urlString) else {
            connectionSucceeded = false
            connectionMessage = "فشل الاتصال: عنوان غير صالح."
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 4)
        request.httpMethod = "GET"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            if statusCode == 200 {
                connectionSucceeded = true
                connectionMessage = "تم الاتصال بالسيرفر بنجاح."
            } else {
                connectionSucceeded = false
                connectionMessage = "فشل الاتصال. كود الاستجابة: \(statusCode)."
            }
        } catch {
            connectionSucceeded = false
            connectionMessage = "فشل الاتصال: تأكد من IP وتشغيل السيرفر."
        }
    }
}

#Preview {
    ProfileView()
}
