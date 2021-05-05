import NonFungibleToken from 0xNonFungibleToken;

pub contract CryptoRecord: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath;
    pub let CollectionPublicPath: PublicPath;
    pub let MinterStoragePath: StoragePath;

    pub var totalSupply: UInt64

    pub resource interface ICryptoRecord {
        pub let artistNames: [String];
        pub let title: String;
        pub let genre: String;
        pub let coverArtUrl: String;
        pub let discArtUrl: String;
        pub let description: String
        pub let mintSize: UInt64;
        pub let mintNumber: UInt64;
        pub let artistEquity: UFix64;
        pub let trackList: [AnyStruct{ITrack}];
        pub let royaltySplits: [AnyStruct{IRoyaltySplit}];
        pub let metadata: {String: String};
    }

    pub struct interface ITrack {
        pub let title: String;
        pub let artists: [AnyStruct{ITrackArtist}];
        pub let metadata: {String: String}?;
    }

    pub struct interface ITrackArtist {
        pub let name: String;
        pub let role: String;
        pub let email: String?;
        pub let metadata: {String: String}?;
    }

    pub struct interface IRoyaltySplit {
        pub let cutPercent: UFix64;
        pub let email: String;
        pub let jobTitle: String;
        pub let metadata: {String: String}?;
    }

    pub resource NFT: NonFungibleToken.INFT, ICryptoRecord {
        pub let id: UInt64;
        pub let artistNames: [String];
        pub let title: String;
        pub let genre: String;
        pub let coverArtUrl: String;
        pub let discArtUrl: String;
        pub let description: String
        pub let mintSize: UInt64;
        pub let mintNumber: UInt64;
        pub let artistEquity: UFix64;
        pub let trackList: [AnyStruct{ITrack}];
        pub let royaltySplits: [AnyStruct{IRoyaltySplit}];
        pub let metadata: {String: String};

        init(
            id: UInt64, 
            artistNames: [String], 
            title: String, 
            genre: String, 
            coverArtUrl: String, 
            discArtUrl: String,
            description: String,
            mintSize: UInt64,
            mintNumber: UInt64,
            artistEquity: UFix64,
            trackList: [AnyStruct{ITrack}],
            royaltySplits: [AnyStruct{IRoyaltySplit}]
        ) {
            self.id = id;
            self.artistNames = artistNames;
            self.title = title;
            self.genre = genre;
            self.coverArtUrl = coverArtUrl;
            self.discArtUrl = discArtUrl;
            self.description = description;
            self.mintSize = mintSize;
            self.mintNumber = mintNumber;
            self.artistEquity = artistEquity;
            self.trackList = trackList;
            self.royaltySplits = royaltySplits;
            self.metadata = {};
        }
    }

    pub resource interface CryptoRecordCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT);
        pub fun getIDs(): [UInt64];
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT;
        pub fun borrowRecord(id: UInt64): &CryptoRecord.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow CryptoRecord reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: CryptoRecordCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT};

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT");
            emit Withdraw(id: token.id, from: self.owner?.address);
            return <-token;
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @CryptoRecord.NFT;
            let id: UInt64 = token.id;
            let oldToken <- self.ownedNFTs[id] <- token;
            emit Deposit(id: id, to: self.owner?.address);
            destroy oldToken;
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        pub fun borrowRecord(id: UInt64): &CryptoRecord.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &CryptoRecord.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

	pub resource NFTMinter {

		pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            artistNames: [String], 
            title: String, 
            genre: String, 
            coverArtUrl: String, 
            discArtUrl: String,
            description: String,
            mintSize: UInt64,
            mintNumber: UInt64,
            artistEquity: UFix64,
            trackList: [AnyStruct{ITrack}],
            royaltySplits: [AnyStruct{IRoyaltySplit}]
        ) {
            emit Minted(id: CryptoRecord.totalSupply)
            
            let token <- create CryptoRecord.NFT(
                id: CryptoRecord.totalSupply, 
                artistNames: artistNames, 
                title: title, 
                genre: genre, 
                coverArtUrl: coverArtUrl, 
                discArtUrl: discArtUrl,
                description: description,
                mintSize: mintSize,
                mintNumber: mintNumber,
                artistEquity: artistEquity,
                trackList: trackList,
                royaltySplits: royaltySplits
            )
			recipient.deposit(token: <- token);

            CryptoRecord.totalSupply = CryptoRecord.totalSupply + (1 as UInt64)
		}
	}

    pub fun fetch(_ from: Address, itemID: UInt64): &CryptoRecord.NFT? {
        let collection = getAccount(from)
            .getCapability(CryptoRecord.CollectionPublicPath)
            .borrow<&CryptoRecord.Collection{CryptoRecord.CryptoRecordCollectionPublic}>()
            ?? panic("Couldn't get collection")
        return collection.borrowRecord(id: itemID)
    }

	init() {
        self.CollectionStoragePath = /storage/CryptoRecordCollection
        self.CollectionPublicPath = /public/CryptoRecordCollection
        self.MinterStoragePath = /storage/CryptoRecordMinter

        self.totalSupply = 0

        let minter <- create NFTMinter()
        destroy self.account.load<@NFTMinter>(from: self.MinterStoragePath)
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
	}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64)
}
