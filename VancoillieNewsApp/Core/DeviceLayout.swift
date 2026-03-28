import SwiftUI
#if os(iOS)
import UIKit
#endif

enum DeviceLayout {
    static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
}
