import Foundation
import CoreBluetooth

/**
Permissions for a characteristic.
- read:   An accessory has read permission for the characteristic.
- write:  An accessory has write permission for the characteristic.
- notify: An accessory can register a notification for updates to the characteristic.
*/
enum CharacteristicPermissions {
    case read, write, notify, extended
}

/**
This extension makes checking a characteristic's permissions cleaner and easier to read. It abstracts away the CBCharacterisProperties class and the raw value bitwise operator logic.
*/
extension CBCharacteristic {

    /// Returns a Set of permissions for the characteristic
    var permissions: Set<CharacteristicPermissions> {
        var permissionsSet = Set<CharacteristicPermissions>()

        if self.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.read)
        }

        if self.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.write)
        }

        if self.properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.notify)
        }
        
        if self.properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.extended)
        }

        return permissionsSet
    }
}
