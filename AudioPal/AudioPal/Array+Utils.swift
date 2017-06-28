//
//  Array+Utils.swift
//  AudioPal
//
//  Created by Danno on 6/27/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

extension Array where Element : Equatable {

    func sortedInsertionIndex(item: Element, isAscendant: (Element, Element) -> Bool) -> Index {
        var first = 0
        var last = self.count - 1
        
        while first <= last {
            let middle = ( last - first ) / 2 + first
            if isAscendant(self[middle], item) {
                first = middle + 1
            } else if isAscendant(item, self[middle]) {
                last = middle - 1
            } else {
                return middle
            }
        }
        
        return last + 1
    }
    
    mutating func sortedInsert(item: Element, isAscendant: (Element, Element) -> Bool) -> Index {
        let index = sortedInsertionIndex(item: item, isAscendant: isAscendant)
        self.insert(item, at: index)
        return index
    }
    
    mutating func sortedUpdate(item: Element, isAscendant: (Element, Element) -> Bool) -> (old: Index, new: Index)? {
        guard let oldIndex = self.index(of: item) else {
            return nil
        }
        self.remove(at: oldIndex)
        let newIndex = sortedInsert(item: item, isAscendant: isAscendant)
        return (oldIndex, newIndex)
    }
}
