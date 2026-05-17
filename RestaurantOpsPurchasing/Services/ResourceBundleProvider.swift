import Foundation

enum ResourceBundleProvider {
    static var current: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle.main
        #endif
    }
}
