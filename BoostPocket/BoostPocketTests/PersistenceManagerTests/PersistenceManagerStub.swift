//
//  PersistenceManagerStub.swift
//  BoostPocketTests
//
//  Created by sihyung you on 2020/11/23.
//  Copyright © 2020 BoostPocket. All rights reserved.
//

import Foundation
import CoreData
import NetworkManager
@testable import BoostPocket

class PersistenceManagerStub: PersistenceManager {
    override init(dataLoader: DataLoader) {
        super.init(dataLoader: dataLoader)
        
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        
        let container = NSPersistentContainer(name: modelName)
        container.persistentStoreDescriptions = [persistentStoreDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                dump(error)
            }
        }
        
        persistentContainer = container
    }
}
