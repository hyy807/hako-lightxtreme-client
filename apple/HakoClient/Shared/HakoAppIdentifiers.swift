import Foundation
 
 
 
 
 
 
 
 

enum HakoAppIdentifiers {
     
    static let base = "feifei.qianbei.com"

     
    static let appBundleID = "feifei.qianbei.com"

     
    static let macAppBundleID = "feifei.qianbei.com"

     
    static let tvAppBundleID = "feifei.qianbei.com"

     
    // Re-signing tools (Sideloadly, AltStore, enterprise certificates) rename the
    // extension, so the real identifier is read from the installed bundle.
    static let packetTunnelExtensionBundleID = HakoRuntimeIdentity.packetTunnelBundleID(default: "feifei.qianbei.com.extension")

     
    static let macPacketTunnelExtensionBundleID = "feifei.qianbei.com.packet-tunnel"

     
    static let controlsExtensionBundleID = "feifei.qianbei.com.controls"

     
    static let shareExtensionBundleID = "feifei.qianbei.com.share"

     
    static let tvPacketTunnelExtensionBundleID = "feifei.qianbei.com.tvextension"

     
     
     
     
     
     
     
     
    // Re-signing tools rewrite the App Group to one owned by the signer. Using the
    // build-time name then yields no shared container ("profile library could not
    // be read"), so the group actually granted to this signature is used.
    static var appGroup: String { HakoRuntimeIdentity.appGroup(default: "group.feifei.qianbei.com") }

     
    static let iCloudContainer = "iCloud.feifei.qianbei.com"

     
    static let backgroundRefreshTask = "feifei.qianbei.com.refresh"

     
    static let keychainService = "feifei.qianbei.com.credentials"
}


/// Resolves identifiers that a re-signature may have changed.
enum HakoRuntimeIdentity {
    private static let cachedGroups: [String] = grantedAppGroups()
    private static var resolvedGroup: String?
    private static let lock = NSLock()

    static func appGroup(default fallback: String) -> String {
        lock.lock(); defer { lock.unlock() }
        if let resolvedGroup { return resolvedGroup }
        var candidates = cachedGroups
        if let index = candidates.firstIndex(of: fallback) { candidates.swapAt(0, index) }
        let chosen = candidates.first {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
        } ?? fallback
        resolvedGroup = chosen
        return chosen
    }

    static func packetTunnelBundleID(default fallback: String) -> String {
        for bundle in [Bundle.main] + pluginBundles() {
            guard let info = bundle.infoDictionary,
                  let ext = info["NSExtension"] as? [String: Any],
                  let point = ext["NSExtensionPointIdentifier"] as? String,
                  point == "com.apple.networkextension.packet-tunnel",
                  let id = bundle.bundleIdentifier else { continue }
            return id
        }
        return fallback
    }

    private static func appBundleURL() -> URL {
        let url = Bundle.main.bundleURL
        // Inside an extension: <App>.app/PlugIns/<Ext>.appex
        if url.pathExtension == "appex" {
            return url.deletingLastPathComponent().deletingLastPathComponent()
        }
        return url
    }

    private static func pluginBundles() -> [Bundle] {
        let plugins = appBundleURL().appendingPathComponent("PlugIns", isDirectory: true)
        let items = (try? FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil)) ?? []
        return items.filter { $0.pathExtension == "appex" }.compactMap(Bundle.init(url:))
    }

    /// App Groups listed in the provisioning profiles shipped with this install.
    private static func grantedAppGroups() -> [String] {
        var bundles = [Bundle.main.bundleURL, appBundleURL()]
        bundles += pluginBundles().map(\.bundleURL)
        var groups: [String] = []
        for url in bundles {
            for name in ["embedded.mobileprovision", "Contents/embedded.provisionprofile"] {
                guard let data = try? Data(contentsOf: url.appendingPathComponent(name)),
                      let plist = provisioningPlist(data),
                      let entitlements = plist["Entitlements"] as? [String: Any],
                      let list = entitlements["com.apple.security.application-groups"] as? [String] else { continue }
                for group in list where !groups.contains(group) { groups.append(group) }
            }
        }
        return groups
    }

    private static func provisioningPlist(_ data: Data) -> [String: Any]? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex) else { return nil }
        let xml = data.subdata(in: start.lowerBound..<end.upperBound)
        return (try? PropertyListSerialization.propertyList(from: xml, format: nil)) as? [String: Any]
    }
}
