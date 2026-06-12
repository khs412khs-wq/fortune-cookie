import SwiftUI
import WidgetKit

struct ContentView: View {
    private let headerImageHeight: CGFloat = 26

    @State private var remainingPersonal = CookieStore.remainingPersonalCount
    @State private var remainingGift = CookieStore.remainingGiftCount
    @State private var personalSlotsUsed = CookieStore.personalSlotsUsed
    @State private var giftSlotsUsed = CookieStore.giftSlotsUsed
    @State private var showRecipientSettings = false
    #if DEBUG
    @State private var showResetConfirm = false
    #endif

    var body: some View {
        VStack(spacing: 0) {
            Image("crack_your_fortune_head")
                .resizable()
                .scaledToFit()
                .frame(height: headerImageHeight)
                .frame(maxWidth: .infinity)
                .padding(.top, 12 + headerImageHeight)
                .padding(.bottom, 10)

            CookieBreakView(
                    remainingPersonal: remainingPersonal,
                    remainingGift: remainingGift,
                    personalSlotsUsed: personalSlotsUsed,
                    giftSlotsUsed: giftSlotsUsed,
                    onBreak: { mode, slotIndex in
                        let result = CookieStore.breakCookie(mode: mode, slotIndex: slotIndex)
                        remainingPersonal = result.remainingPersonal
                        remainingGift = result.remainingGift
                        personalSlotsUsed = result.personalSlotsUsed
                        giftSlotsUsed = result.giftSlotsUsed
                        if result.success,
                           let fortune = result.fortune,
                           mode == .personal {
                            FortunePresenter.presentFortune(
                                fortune,
                                remainingPersonal: result.remainingPersonal,
                                remainingGift: result.remainingGift
                            )
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                        return result
                    },
                    onGiftShareCompleted: { result in
                        remainingPersonal = result.remainingPersonal
                        remainingGift = result.remainingGift
                        personalSlotsUsed = result.personalSlotsUsed
                        giftSlotsUsed = result.giftSlotsUsed
                        WidgetCenter.shared.reloadAllTimelines()
                    },
                    onPersonalShareCompleted: { result in
                        remainingPersonal = result.remainingPersonal
                        remainingGift = result.remainingGift
                        personalSlotsUsed = result.personalSlotsUsed
                        giftSlotsUsed = result.giftSlotsUsed
                        WidgetCenter.shared.reloadAllTimelines()
                    }
            )
            .frame(maxHeight: .infinity)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showRecipientSettings) {
            GiftRecipientSettingsView()
        }
        .onAppear {
            CookieStore.resetIfNeeded()
            refreshCounts()
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            Button {
                showResetConfirm = true
            } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange.opacity(0.85))
                    .padding(16)
            }
            .confirmationDialog("쿠키 초기화", isPresented: $showResetConfirm) {
                Button("초기화", role: .destructive) {
                    CookieStore.debugReset()
                    refreshCounts()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("남은 횟수를 모두 초기화할까요?")
            }
        }
        #endif
    }

    private func refreshCounts() {
        remainingPersonal = CookieStore.remainingPersonalCount
        remainingGift = CookieStore.remainingGiftCount
        personalSlotsUsed = CookieStore.personalSlotsUsed
        giftSlotsUsed = CookieStore.giftSlotsUsed
    }
}

struct GiftRecipientSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var recipients: [GiftRecipient] = GiftRecipientStore.load()
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var showLimitAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("이름", text: $name)
                    TextField("전화번호 (선택)", text: $phoneNumber)
                        .keyboardType(.phonePad)

                    Button("선물 받을 사람 추가") {
                        addRecipient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("새로운 사람")
                } footer: {
                    Text("선물 보내기에서 이 목록의 사람을 선택할 수 있어요. 전화번호를 입력하면 문자 앱으로 바로 보낼 수 있어요.")
                }

                Section("선물 받을 사람") {
                    if recipients.isEmpty {
                        Text("아직 등록된 사람이 없어요")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recipients) { recipient in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipient.name)
                                    .font(.body.weight(.semibold))

                                if !recipient.phoneNumber.isEmpty {
                                    Text(recipient.phoneNumber)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("전화번호 없음")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .onDelete(perform: deleteRecipients)
                    }
                }
            }
            .navigationTitle("선물 받을 사람")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .alert("최대 \(GiftRecipientStore.maxRecipients)명까지 등록할 수 있어요", isPresented: $showLimitAlert) {
                Button("확인", role: .cancel) {}
            }
        }
    }

    private func addRecipient() {
        guard GiftRecipientStore.add(name: name, phoneNumber: phoneNumber) else {
            showLimitAlert = true
            return
        }

        recipients = GiftRecipientStore.load()
        name = ""
        phoneNumber = ""
        HapticManager.tap()
    }

    private func deleteRecipients(at offsets: IndexSet) {
        for index in offsets {
            GiftRecipientStore.delete(id: recipients[index].id)
        }
        recipients = GiftRecipientStore.load()
    }
}

#Preview {
    ContentView()
}
