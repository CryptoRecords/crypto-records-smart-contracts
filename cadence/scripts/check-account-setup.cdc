import CryptoRecord from 0xCryptoRecord;
import NonFungibleToken from 0xNonFungibleToken;

pub fun main(address: Address): Bool {
    if getAccount(address).getCapability(/public/CryptoRecordCollection)!.borrow<&{NonFungibleToken.CollectionPublic}>() == nil {
        return false;
    }
    return true;
}