import SwiftUI
import WebKit

/// Stored in the app's standard defaults so re-signing does not require App Group access.
struct QianbeiLaunchView: View {
    @AppStorage("qianbei.launch.hideWelcome") private var hideWelcome = false
    @AppStorage("qianbei.launch.skipWebsite") private var skipWebsite = false
    @State private var started = false
    @State private var showWelcome = false
    @State private var showWebsite = false
    private let address = "https://t.me/qianbeibuzu"

    var body: some View {
        AppShellView()
            .overlay {
                if showWelcome {
                    ZStack {
                        Color.black.opacity(0.45).ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("欢迎使用千杯clash").font(.title2.bold())
                            Text("欢迎加入千杯社区").font(.body)
                            Text(verbatim: address)
                                .font(.callout)
                                .textSelection(.enabled)
                                .accessibilityIdentifier("qianbei.welcome.address")
                            Button("前往社区") { finishWelcome() }
                                .buttonStyle(.borderedProminent)
                            Button("不再提醒") {
                                hideWelcome = true
                                finishWelcome()
                            }
                            Button("关闭") { finishWelcome() }
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
            .fullScreenCover(isPresented: $showWebsite) {
                VStack(spacing: 0) {
                    HStack {
                        Text("千杯社区").font(.headline)
                        Spacer()
                        Button("下次不再进入") {
                            skipWebsite = true
                            showWebsite = false
                        }
                        .accessibilityIdentifier("qianbei.website.disable")
                        Button("关闭") { showWebsite = false }
                            .accessibilityIdentifier("qianbei.website.close")
                    }
                    .padding()
                    Text(verbatim: address).font(.caption).padding(.bottom, 8)
                    QianbeiCommunityWebView()
                }
                .background(Color(uiColor: .systemBackground))
            }
            .onAppear {
                guard !started else { return }
                started = true
                showWelcome = !hideWelcome
                if hideWelcome { showWebsite = !skipWebsite }
            }
    }

    private func finishWelcome() {
        showWelcome = false
        // Present only after the welcome has closed; never reopen on foregrounding.
        showWebsite = !skipWebsite
    }
}

private struct QianbeiCommunityWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.navigationDelegate = context.coordinator
        if let url = URL(string: "https://t.me/qianbeibuzu") {
            view.load(URLRequest(url: url))
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Keep launch navigation inside the app rather than switching to Telegram.
            let scheme = navigationAction.request.url?.scheme?.lowercased()
            decisionHandler(scheme == "https" || scheme == "http" || scheme == "about" ? .allow : .cancel)
        }
    }
}
