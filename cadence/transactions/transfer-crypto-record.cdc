import CryptoRecord from 0xCryptoRecord;
import NonFungibleToken from 0xNonFungibleToken;

transaction(recipient: Address, withdrawID: UInt64) {
    prepare(signer: AuthAccount) {
        let recipient = getAccount(recipient)
        let collectionRef = signer.borrow<&CryptoRecord.Collection>(from: CryptoRecord.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")
        let depositRef = recipient.getCapability(CryptoRecord.CollectionPublicPath)!.borrow<&{NonFungibleToken.CollectionPublic}>()!
        let nft <- collectionRef.withdraw(withdrawID: withdrawID)
        depositRef.deposit(token: <-nft)
    }
}