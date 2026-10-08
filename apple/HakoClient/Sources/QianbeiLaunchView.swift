import Foundation
import SwiftUI

/// Launch gate for the branded build: shows the community notice once, then hands
/// the Telegram address to the system so it opens in the browser (or the Telegram app).
struct QianbeiLaunchView: View {
    /// "不再提醒": the welcome notice is shown once and stays dismissed.
    @AppStorage("qianbei.launch.hideWelcome") private var hideWelcome = false
    /// "下次不再进入": launching no longer jumps out to the channel.
    @AppStorage("qianbei.launch.skipChannel") private var skipChannel = false
    @Environment(\.openURL) private var openURL
    @State private var started = false
    @State private var showsWelcome = false

    /// The address handed out at launch. A t.me link is handled by the system,
    /// which opens the Telegram app when it is installed and Safari otherwise.
    static let channel = URL(string: "https://t.me/qianbeibuzu")!

    var body: some View {
        AppShellView()
            .overlay {
                if showsWelcome { welcome }
            }
            .onAppear(perform: startOnce)
    }

    private func startOnce() {
        guard !started else { return }
        started = true
        showsWelcome = !hideWelcome
        // The jump happens once per launch, and returning to the app lands on the
        // main page because the channel is opened outside the app.
        visitChannelIfPermitted()
    }

    private func visitChannelIfPermitted() {
        guard !skipChannel else { return }
        openURL(Self.channel)
    }

    private var welcome: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("欢迎使用千杯clash")
                    .font(.title2.weight(.bold))
                Text("欢迎加入千杯社区")
                    .font(.body)
                Text(verbatim: Self.channel.absoluteString)
                    .font(.callout)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("qianbei.welcome.address")
                Button("前往频道") {
                    showsWelcome = false
                    openURL(Self.channel)
                }
                .buttonStyle(.borderedProminent)
                Button("下次不再进入") {
                    skipChannel = true
                    hideWelcome = true
                    showsWelcome = false
                }
                .accessibilityIdentifier("qianbei.welcome.skip")
                Button("不再提醒") {
                    hideWelcome = true
                    showsWelcome = false
                }
                .accessibilityIdentifier("qianbei.welcome.hide")
                Button("关闭") {
                    showsWelcome = false
                }
                .accessibilityIdentifier("qianbei.welcome.close")
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(24)
            .accessibilityAddTraits(.isModal)
        }
        .accessibilityIdentifier("qianbei.welcome")
    }
}
