import Foundation

// Resource lookup that works for both .app bundles and CLI (SPM) builds.
// - .app: resources are flat in Contents/Resources/ (Bundle.main)
// - CLI: resources are in the SPM module bundle
enum AppResources {
    static func url(forResource name: String, withExtension ext: String?) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        return Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources")
    }
}
