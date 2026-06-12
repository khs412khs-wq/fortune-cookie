import SwiftUI

struct WidgetGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    steps
                    tip
                }
                .padding(24)
            }
            .background(Color(red: 0.12, green: 0.08, blue: 0.18))
            .navigationTitle("위젯 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("🥠")
                .font(.system(size: 56))

            Text("잠금화면에서\n포츈쿠키를 부수세요")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
    }

    private var steps: some View {
        VStack(spacing: 16) {
            stepCard(
                number: 1,
                icon: "lock.fill",
                title: "잠금화면 길게 누르기",
                detail: "iPhone 잠금화면에서 홈 버튼이나 화면을 길게 누르세요."
            )
            stepCard(
                number: 2,
                icon: "plus.circle.fill",
                title: "맞춤하기 → 위젯 추가",
                detail: "맞춤하기를 누른 뒤, 위젯 영역에서 + 버튼을 탭하세요."
            )
            stepCard(
                number: 3,
                icon: "hand.tap.fill",
                title: "포츈쿠키 선택",
                detail: "포츈쿠키를 찾아 원형 또는 직사각형 위젯을 추가하세요."
            )
        }
    }

    private func stepCard(number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var tip: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)

            Text("홈 화면 위젯에서도 부수기 버튼으로 바로 열 수 있어요.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    WidgetGuideSheet()
}
