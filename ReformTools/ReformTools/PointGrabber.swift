//
//  PointGrabber.swift
//  ReformTools
//
//  Created by Laszlo Korte on 20.08.15.
//  Copyright © 2015 Laszlo Korte. All rights reserved.
//

import ReformMath
import ReformCore
import ReformStage

private enum State {
    case Idle
    case Searching(FormIdentifier, SearchingResult)
}

private enum SearchingResult {
    case None
    case Found(position: Vec2d, point: EntityPoint, cycle: Int)
}

class PointGrabber {
    
    private var state : State = .Idle
    let grabUI : GrabUI
    let entityFinder : EntityFinder
    let pointFinder : PointFinder
    let radius : Double
    
    init(stage : Stage, grabUI : GrabUI, radius: Double) {
        self.grabUI = grabUI
        self.entityFinder = EntityFinder(stage: stage)
        self.pointFinder = PointFinder(stage: stage)
        self.radius = radius
    }
    
    func refresh() {
        if case .Searching(let formId, let result) = state,
            let entity = entityFinder.getEntity(formId) {
            
            let allPoints = entity.points
            
            if case .Found(_, let current, _) = result,
                let updated = pointFinder.getUpdatedPoint(current){
                grabUI.state = .Active(updated, allPoints)
            } else {
                grabUI.state = .Show(allPoints)
            }
            
        } else {
            state = .Idle
            grabUI.state = .Hide
        }
    }
    
    func enable(formId: FormIdentifier) {
        state = .Searching(formId, .None)
        refresh()
    }
    
    func disable() {
        state = .Idle
        refresh()
    }
    
    func searchAt(position: Vec2d) {
        if case .Searching(let formId, let oldResult) = state {
            
            switch oldResult {
            case .Found(_, _, let cycle):
                state = .Searching(formId, resultFor(formId, position: position, cycle: cycle))
            case .None:
                state = .Searching(formId, resultFor(formId, position: position, cycle: 0))
            }
        }
        
        refresh()
    }
    
    func cycle() {
        if case .Searching(let formId, .Found(let pos, _, let cycle)) = state {
            
            state =  .Searching(formId, resultFor(formId, position: pos, cycle: cycle+1))
        }
        
    }
    
    private func resultFor(formId : FormIdentifier, position: Vec2d, cycle: Int) -> SearchingResult {
        
        guard let entity = entityFinder.getEntity(formId) else {
            return .None
        }
        let points = entity.points.filter({distance(point: $0.position,point: position) <= radius})
        
        if points.count > 0 {
            return .Found(position: position, point: points[cycle%points.count], cycle: cycle)
        } else {
            return .None
        }
        
    }
    
    var current : EntityPoint? {
        if case .Searching(_, .Found(_, let point, _)) = state {
            return point
        } else {
            return nil
        }
    }
    
    
}