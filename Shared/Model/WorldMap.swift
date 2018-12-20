//
//  WorldMap.swift
//  MetalCity
//
//  Created by Andy Qua on 20/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

class WorldMap {
    static let instance : WorldMap = WorldMap()
    
    var world : [[MapItem]]
    
    private init() {
        world = Array(repeating: Array(repeating: .unclaimed, count: WORLD_SIZE), count: WORLD_SIZE)
    }

    func cellAt( _ x : Int, _ y : Int) -> MapItem {
        
        let cx = x.clamped(to: 0...WORLD_SIZE-1)
        let cy = y.clamped(to: 0...WORLD_SIZE-1)
        return self.world[cx][cy]
    }
    
    func addValue( _ x : Int, _ y : Int, val : MapItem ) {
        let cx = x.clamped(to: 0...WORLD_SIZE-1)
        let cy = y.clamped(to: 0...WORLD_SIZE-1)
        self.world[cx][cy].insert(val)

    }
}
