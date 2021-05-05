import CryptoRecord from 0xCryptoRecord;
import NonFungibleToken from  0xNonFungibleToken;

transaction(
  recipient: Address,
  title: String,
  artistNames: [String],
  genre: String,
  coverArtUrl: String,
  discArtUrl: String,
  description: String,
  mintSize: UInt64,
  artistEquity: UFix64,
  tracklist: [AnyStruct{CryptoRecord.ITrack}],
  royaltySplits: [AnyStruct{CryptoRecord.IRoyaltySplit}]
) {

    let minter: &CryptoRecord.NFTMinter

    prepare(signer: AuthAccount) {
          self.minter = signer.borrow<&CryptoRecord.NFTMinter>(from: /storage/CryptoRecordMinter)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        let recipient = getAccount(recipient)
        let receiver = recipient
            .getCapability(/public/CryptoRecordCollection)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
        
        var i: UInt64 = 1;
        while (i <= mintSize) {
            self.minter.mintNFT(
                recipient: receiver,
                artistNames: artistNames,
                title: title,
                genre: genre,
                coverArtUrl: coverArtUrl,
                discArtUrl: discArtUrl,
                description: description,
                mintSize: mintSize,
                mintNumber: i,
                artistEquity: artistEquity,
                trackList: [],
                royaltySplits: []
            );
            i = i + (1 as UInt64);
        }

    }
}