//
//  Migration.swift
//  Hacker News
//
//  Created by Jonathan on 5/14/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import Foundation
import RealmSwift

let AppDefaultRealmConfiguration = Realm.Configuration(
    // Set the new schema version. This must be greater than the previously used
    // version (if you've never set a schema version before, the version is 0).
    schemaVersion: 6,
    
    // Set the block which will be called automatically when opening a Realm with
    // a schema version lower than the one set above
    migrationBlock: { migration, oldSchemaVersion in
        // We haven’t migrated anything yet, so oldSchemaVersion == 0
        if (oldSchemaVersion < 1) {
            // Nothing to do!
            // Realm will automatically detect new properties and removed properties
            // And will update the schema on disk automatically
        }
    }
)
