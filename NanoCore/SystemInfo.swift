//
//  SystemInfo.swift
//  NanoCore
//
//  Created by Richard Henry on 1/22/24.
//

import Foundation

/// The name of the system device model, e.g. "iPhone15,3" or "MacBookPro18,2"
public func getDeviceModelName() -> String? {
    #if TARGET_OS_IPHONE
    let propertyName = "hw.machine"
    #else
    let propertyName = "hw.model"
    #endif

    var size: Int = 0
    if sysctlbyname(propertyName, nil, &size, nil, 0) != 0 {
        return nil
    }

    var model = [CChar](repeating: 0, count: size)
    if sysctlbyname(propertyName, &model, &size, nil, 0) != 0 {
        return nil
    }

    return String(cString: model)
}
