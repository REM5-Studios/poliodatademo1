//
//  AppModel.swift
//  Data_Viz_Demo1
//
//  Created by amir berenjian on 8/23/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // Track current chart view mode
    var chartViewMode: ChartViewMode = .world
    
    enum ChartViewMode: Equatable {
        case world
        case region(String)
        case country(code: String, name: String)
        
        var displayName: String {
            switch self {
            case .world:
                return "World"
            case .region(let name):
                return name
            case .country(_, let name):
                return name
            }
        }
    }
}
