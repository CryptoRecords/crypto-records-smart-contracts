import CryptoRecord from 0xCryptoRecord;
import NonFungibleToken from  0xNonFungibleToken;

transaction {
    prepare(_ signer: AuthAccount) {
        let existingCollection = signer.borrow<&CryptoRecord.Collection>(from: /storage/CryptoRecordCollection);

        if (existingCollection != nil) {
            return;
        }

        signer.save(<-CryptoRecord.createEmptyCollection(), to: /storage/CryptoRecordCollection);

        signer.unlink(/public/CryptoRecordCollection);
        signer.link<&CryptoRecord.Collection{NonFungibleToken.CollectionPublic, CryptoRecord.CryptoRecordCollectionPublic}>(/public/CryptoRecordCollection, target: /storage/CryptoRecordCollection);
    }
}