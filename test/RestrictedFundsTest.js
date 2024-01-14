const RestrictedFunds = artifacts.require("RestrictedFunds");

contract("RestrictedFunds", (accounts) => {
    let restrictedFunds;
    const owner = accounts[0];
    const authorizedKey = accounts[1];
    const thirdParty = accounts[2];
    const cancellationDelay = 604800; // 1 week in seconds
    const largeEtherAccount = accounts[9] //suppose large eth account 


    beforeEach(async () => {
        restrictedFunds = await RestrictedFunds.new(authorizedKey, { from: owner });
    });

    it("should correctly initialize the contract with the owner and authorized key", async () => {
        assert.equal(await restrictedFunds.owner(), owner, "The owner is not correctly set");
        assert.equal(await restrictedFunds.authorizedKey(), authorizedKey, "The authorized key is not correctly set");
    });

    it("should allow the authorized key to transfer funds", async () => {
        await web3.eth.sendTransaction({ from: largeEtherAccount, to: restrictedFunds.address, value: web3.utils.toWei("1", "ether") });
        const initialBalance = await web3.eth.getBalance(thirdParty);
        const amount = web3.utils.toWei("0.5", "ether");
        await restrictedFunds.transferFunds(thirdParty, amount, { from: authorizedKey });
        const finalBalance = await web3.eth.getBalance(thirdParty);
        assert.equal(finalBalance, BigInt(initialBalance) + BigInt(amount), "Funds were not correctly transferred");
    });

    it("should not allow non-authorized accounts to transfer funds", async () => {
        try {
            await restrictedFunds.transferFunds(thirdParty, web3.utils.toWei("0.1", "ether"), { from: thirdParty });
            assert.fail("The transfer should have thrown an error");
        } catch (error) {
            assert.include(error.message, "Not authorized", "The error message should contain 'Not authorized'");
        }
    });

    it("should allow the owner to request cancellation", async () => {
        let result = await restrictedFunds.requestCancellation({ from: owner });
        assert.isTrue(await restrictedFunds.isCancellationRequestedByOwner(), "Cancellation request was not set");
        const log = result.logs[0];
        assert.equal(log.event, "CancelRequest", "An event should be emit");
    });

    it("should not allow non-owners to request cancellation", async () => {
        try {
            await restrictedFunds.requestCancellation({ from: thirdParty });
            assert.fail("The request should have thrown an error");
        } catch (error) {
            assert.include(error.message, "Not owner", "The error message should contain 'Not owner'");
        }
    });

    it("should allow the owner to finalize cancellation after the delay", async () => {
        await restrictedFunds.requestCancellation({ from: owner });
        await increaseTime(cancellationDelay + 1);
        await restrictedFunds.finalizeCancellation({ from: owner });
        assert.isFalse(await restrictedFunds.isCancellationRequestedByOwner(), "Cancellation was not finalized");
        assert.isTrue(await restrictedFunds.authorizedKey() == owner, "Cancellation was not finalized");
    });
    
    
    it("should allow the owner and the authorized address to reset the cancellation", async () => {
        await restrictedFunds.requestCancellation({ from: owner });
        await restrictedFunds.resetCancellationRequestOwner({ from: owner });
        await restrictedFunds.resetCancellationRequestAuthorized({ from: authorizedKey });
        await restrictedFunds.resetCancellationRequest();
        assert.isFalse(await restrictedFunds.isCancellationPending(), "Cancellation should be aborted");
        try {
            await restrictedFunds.requestCancellation({ from: owner });
            assert.fail("The transfer should have thrown an error");
        } catch (error) {
            assert.include(error.message, "delay", "The owner should not be able to request a new cancellation directly");
        }
    });
    
    function increaseTime(duration) {
        const id = Date.now();
        return new Promise((resolve, reject) => {
            web3.currentProvider.send({
                jsonrpc: "2.0",
                method: "evm_increaseTime",
                params: [duration],
                id: id,
            }, err1 => {
                if (err1) return reject(err1);

                web3.currentProvider.send({
                    jsonrpc: "2.0",
                    method: "evm_mine",
                    id: id + 1,
                }, (err2, res) => {
                    return err2 ? reject(err2) : resolve(res);
                });
            });
        });
    }
});
