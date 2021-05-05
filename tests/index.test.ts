import path from 'path';
import { exec, } from 'child_process';
import t from '@onflow/types';
import {
    init,
    getAccountAddress,
    deployContractByName,
    getTransactionCode,
    sendTransaction,
    getScriptCode,
    executeScript
} from 'flow-js-testing/dist';

const basePath = path.resolve(__dirname, '../cadence');

beforeAll(() => {
    init(basePath);
});

let addressMap;

describe('CryptoRecord', () => {
    let Minter, Receiver1, Receiver2;

    beforeAll(async () => {
        Minter = await getAccountAddress('Minter');
        Receiver1 = await getAccountAddress('Receiver1');
        Receiver2 = await getAccountAddress('Receiver2');
        addressMap = { NonFungibleToken: Minter, CryptoRecord: Minter };
        await deployContractByName({ to: Minter, name: 'NonFungibleToken', update: true });
        await deployContractByName({ to: Minter, name: 'CryptoRecord', addressMap, update: true });
    });

    it('should be able to initialize user accounts', async () => {
        await setupAccount(Receiver1);
        const isReceiver1Setup = await checkAccountSetup(Receiver1);
        await setupAccount(Receiver2);
        const isReceiver2Setup = await checkAccountSetup(Receiver2);
        expect(isReceiver1Setup).toEqual(true);
        expect(isReceiver2Setup).toEqual(true);
    });

    it('should mint correct number of CryptoRecords', async () => {
        await mintCryptoRecord(Minter, Receiver1);
        const result = await fetchCryptoRecords(Receiver1);
        expect(result.length).toEqual(10);
        const cryptoRecord = result[0];
        expect(cryptoRecord).toBeDefined();
        expect(cryptoRecord.title).toEqual('test title');
    });

    it('shouldn\'t be able to withdraw an NFT that doesn\'t exist in a collection', async () => {
        let result = true;
        try {
            await transferCryptoRecord(Receiver1, Receiver2, 777777);
        }
        catch {
            result = false;
        }
        expect(result).toEqual(false);
    });

    it('should be able to withdraw an NFT and transfer to another account\'s collection', async () => {
        await transferCryptoRecord(Receiver1, Receiver2, 1);
        const result = await fetchCryptoRecords(Receiver2);
        const cryptoRecord = result[0];
        expect(cryptoRecord).toBeDefined();
        expect(cryptoRecord.title).toEqual('test title');
    });


});

const setupAccount = async (signerAddress) => {
    const code = await getTransactionCode({ name: 'setup-account', addressMap });
    return await sendTransaction({ code, signers: [signerAddress] });
}

const checkAccountSetup = async (address) => {
    const code = await getScriptCode({ name: 'check-account-setup', addressMap });
    return await executeScript({ code, args: [[address, t.Address]] });
}

const mintCryptoRecord = async (signerAddress, recipientAddress) => {
    const code = await getTransactionCode({ name: 'mint-crypto-record', addressMap });
    return await sendTransaction({
        code,
        args: [
            [recipientAddress, t.Address],
            ['test title', t.String],
            [['test artist'], t.Array(t.String)],
            ['test genre', t.String],
            ['test coverArtUrl', t.String],
            ['test discArtUrl', t.String],
            ['test description', t.String],
            [10, t.UInt64],
            ['1.00', t.UFix64],
            [[], t.Array(t.Struct)],
            [[], t.Array(t.Struct)],
        ],
        signers: [signerAddress]
    });
}

const fetchCryptoRecords = async (address) => {
    const code = await getScriptCode({ name: 'fetch-crypto-records', addressMap });
    return await executeScript({ code, args: [[address, t.Address]] });
}

const transferCryptoRecord = async (signerAddress, recipientAddress, cryptoRecordId) => {
    const code = await getTransactionCode({ name: 'transfer-crypto-record', addressMap });
    return await sendTransaction({
        code,
        signers: [signerAddress],
        args: [
            [recipientAddress, t.Address],
            [cryptoRecordId, t.UInt64]
        ]
    });
}