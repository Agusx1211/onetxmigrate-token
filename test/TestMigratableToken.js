const TestToken = artifacts.require('./TestToken.sol');
const MigratableToken = artifacts.require('./MigratableToken.sol');


contract('Migratable token', function (accounts) {
    it("Should migrate tokens with one tx", async function() {
        const originalToken = await TestToken.new();
        const migratableToken = await MigratableToken.new(originalToken.address);

        await originalToken.setBalance(accounts[0], 1000);

        const migrationAddress = await migratableToken.migrationAddress(accounts[0]);

        // Only one transfer
        await originalToken.transfer(migrationAddress, 750, { from: accounts[0] });

        assert.equal((await migratableToken.balanceOf(accounts[0])).toString(), "750");

        // Try transfer some
        await migratableToken.transfer(accounts[1], 250, { from: accounts[0] });

        // Check transfer result
        assert.equal((await migratableToken.balanceOf(accounts[1])).toString(), "250");
    });
});
