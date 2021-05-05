import NonFungibleToken from 0xNonFungibleToken;
import CryptoRecord from 0xCryptoRecord;

pub fun main(address: Address): [&CryptoRecord.NFT] {
    let res: [&CryptoRecord.NFT] = [];
    if let collection = getAccount(address).getCapability<&CryptoRecord.Collection{NonFungibleToken.CollectionPublic, CryptoRecord.CryptoRecordCollectionPublic}>(/public/CryptoRecordCollection).borrow() {
        let ids = collection.getIDs();
        for id in ids {
            if let recordRef = collection.borrowRecord(id: id) {
                res.append(recordRef)
            }
        }
    }

    return res
}