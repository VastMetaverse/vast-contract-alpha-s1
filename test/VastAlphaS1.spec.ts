import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades, waffle } from "hardhat";

import { VastToken, VastAlphaS1 } from "../typechain";

describe("VastAlphaS1", function () {
  this.timeout(0);

  let contractOwner: SignerWithAddress;
  let signer: SignerWithAddress;
  let contract: VastAlphaS1;
  let signerContract: VastAlphaS1;

  let tokenContract: VastToken;

  beforeEach(async () => {
    [contractOwner, signer] = await ethers.getSigners();

    const LayerZeroEndpointMock = await ethers.getContractFactory(
      "LZEndpointMock"
    );
    const lzEndpointMock = await LayerZeroEndpointMock.deploy(1);

    const VastToken = await ethers.getContractFactory(
      "VastToken",
      contractOwner
    );
    tokenContract = (await upgrades.deployProxy(
      VastToken,
      ["VAST Loyalty Program", "VAST", lzEndpointMock.address],
      {
        kind: "uups",
      }
    )) as VastToken;

    const VastAlphaS1 = await ethers.getContractFactory(
      "VastAlphaS1",
      contractOwner
    );
    contract = (await upgrades.deployProxy(
      VastAlphaS1,
      [
        tokenContract.address,
        // lzEndpointMock.address
      ],
      {
        kind: "uups",
      }
    )) as VastAlphaS1;

    await contract.createAssetType("Hoodie", 1, 2500, 2);

    signerContract = contract.connect(signer) as VastAlphaS1;
  });

  describe("ERC721", () => {
    it("should have correct name and symbol", async () => {
      const name = await contract.name();
      const symbol = await contract.symbol();
      await expect(name).to.equal("VAST: ALPHA S1");
      await expect(symbol).to.equal("VastAlphaS1");
    });

    it("should support ERC721 interface", async () => {
      const supportsInterface = await contract.supportsInterface("0x80ac58cd");
      await expect(supportsInterface).to.equal(true);
    });
  });

  describe("mint", async () => {
    it("should mark the owner as admin", async () => {
      await contract.adminMint(contractOwner.address, 1, 1);
      await expect(
        await contract.balanceOfType(contractOwner.address, 1)
      ).to.equal(1);
    });
  });

  describe("mint with points", async () => {
    it("should allow mint with just enough points", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 2000);

      const tokensToMint = 1;

      await contract.setAssetTypeCost(1, 2000);

      await signerContract.mint(1, tokensToMint);
      await expect(
        await signerContract.balanceOfType(signer.address, 1)
      ).to.equal(tokensToMint);
      await expect(await tokenContract.balanceOf(signer.address)).to.equal(0);
      await expect(await signerContract.totalSupplyOfType(1)).to.equal(1);
    });

    it("should allow 100 mints with just enough points", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 200000);

      const tokensToMint = 100;

      await contract.setAssetTypeCost(1, 2000);

      await signerContract.mint(1, tokensToMint);
      await expect(
        await signerContract.balanceOfType(signer.address, 1)
      ).to.equal(tokensToMint);
      await expect(await tokenContract.balanceOf(signer.address)).to.equal(0);
      await expect(await signerContract.totalSupplyOfType(1)).to.equal(100);
    });

    it("should allow mint with extra points", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 2000 * 2);

      const tokensToMint = 1;

      await contract.setAssetTypeCost(1, 2000);

      await signerContract.mint(1, tokensToMint);
      await expect(
        await signerContract.balanceOfType(signer.address, 1)
      ).to.equal(tokensToMint);
      await expect(await tokenContract.balanceOf(signer.address)).to.equal(
        2000
      );
      await expect(await signerContract.totalSupplyOfType(1)).to.equal(1);
    });

    it("should allow 100 mints with extra points", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 200000 * 2);

      const tokensToMint = 100;

      await contract.setAssetTypeCost(1, 2000);

      await signerContract.mint(1, tokensToMint);
      await expect(
        await signerContract.balanceOfType(signer.address, 1)
      ).to.equal(tokensToMint);
      await expect(await tokenContract.balanceOf(signer.address)).to.equal(
        200000
      );
      await expect(await signerContract.totalSupplyOfType(1)).to.equal(100);
    });

    it("should not allow 101 mints with not enough points", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 200000);

      const tokensToMint = 101;

      await contract.setAssetTypeCost(1, 2000);

      const transaction = signerContract.mint(1, tokensToMint);
      await expect(transaction).to.be.revertedWith("Not enough points");
    });

    it("should allow 100 mints with not enough points", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 200000);

      const tokensToMint = 100;

      await contract.setAssetTypeCost(1, 2001);

      const transaction = signerContract.mint(1, tokensToMint);
      await expect(transaction).to.be.revertedWith("Not enough points");
    });
  });

  // describe("mint with discounts", () => {
  //   it("should allow 30% discount with METIS", async () => {
  //     await contract.createAssetType("Hat", 10000, 100, 2);

  //     const tokensToMint = 50;

  //     await contract.mintWithMetis(2, tokensToMint, { value: getValue(3500) });
  //     await expect(
  //       await contract.balanceOfType(contractOwner.address, 2)
  //     ).to.equal(tokensToMint);
  //     await expect(await contract.totalSupplyOfType(2)).to.equal(50);
  //   });

  //   it("should not allow 30% discount with METIS", async () => {
  //     await contract.createAssetType("Hat", 10000, 100, 2);

  //     const tokensToMint = 50;

  //     const transaction = contract.mintWithMetis(2, tokensToMint, {
  //       value: getValue(3498),
  //     });
  //     await expect(transaction).to.be.revertedWith("Not enough METIS");
  //   });

  //   it("should allow 0% discount with METIS for 1 max", async () => {
  //     await contract.createAssetType("Hat", 10000, 1, 2);

  //     await contract.mintWithMetis(2, 1, { value: getValue(100) });
  //     await expect(
  //       await contract.balanceOfType(contractOwner.address, 2)
  //     ).to.equal(1);
  //     await expect(await contract.totalSupplyOfType(2)).to.equal(1);
  //   });

  //   it("should not allow discount for 1 max", async () => {
  //     await contract.createAssetType("Hat", 10000, 1, 2);

  //     const transaction = contract.mintWithMetis(2, 1, {
  //       value: getValue(99),
  //     });
  //     await expect(transaction).to.be.revertedWith("Not enough METIS");
  //   });

  //   it("should allow 30% discount with METIS for 10 max", async () => {
  //     await contract.createAssetType("Hat", 10000, 10, 2);

  //     const tokensToMint = 5;

  //     await contract.mintWithMetis(2, tokensToMint, { value: getValue(350) });
  //     await expect(
  //       await contract.balanceOfType(contractOwner.address, 2)
  //     ).to.equal(tokensToMint);
  //     await expect(await contract.totalSupplyOfType(2)).to.equal(5);
  //   });

  //   it("should not allow more than 30% discount with METIS for 10 max", async () => {
  //     await contract.createAssetType("Hat", 10000, 10, 2);

  //     const tokensToMint = 5;

  //     const transaction = contract.mintWithMetis(2, tokensToMint, {
  //       value: getValue(349),
  //     });
  //     await expect(transaction).to.be.revertedWith("Not enough METIS");
  //   });
  // });

  describe("adminMint", async () => {
    let adminSigner: SignerWithAddress;

    beforeEach(async () => {
      adminSigner = contractOwner;
      await contract.setAssetTypeCost(1, 1000);
    });

    it("should throw if the caller it's not an admin", async () => {
      const transaction = contract
        .connect(signer)
        .adminMint(signer.address, 1, 1);
      await expect(transaction).to.be.revertedWith("Caller is not an admin");
    });
    it("should throw if the caller it's trying to mint 0 tokens", async () => {
      const transaction = contract.adminMint(contractOwner.address, 1, 0);
      await expect(transaction).to.be.revertedWith("Invalid amount");
    });
    // it("should throw if there's not enough tokens available for minting", async () => {
    //   const transaction = contract.adminMint(urisToMint.length + 1);
    //   await expect(transaction).to.be.revertedWith("Not enough tokens to mint");
    // });
    it("should mint the requested amount of tokens", async () => {
      const tokensToMint = 2;
      await contract.adminMint(contractOwner.address, 1, tokensToMint);
      await expect(
        await contract.balanceOfType(adminSigner.address, 1)
      ).to.equal(tokensToMint);
    });
  });

  describe("pause", async () => {
    it("should throw if the caller it's not the owner of the contract", async () => {
      const transaction = contract.connect(signer).pause();
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should pause the contract", async () => {
      await contract.pause();
      await expect(await contract.paused()).to.equal(true);
    });
  });

  describe("unpause", async () => {
    beforeEach(async () => {
      await contract.pause();
    });

    it("should throw if the caller it's not the owner of the contract", async () => {
      const transaction = contract.connect(signer).unpause();
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should unpause the contract", async () => {
      await contract.unpause();
      await expect(await contract.paused()).to.equal(false);
    });
  });

  describe("get cost", async () => {
    it("should expose current minting cost", async () => {
      const cost = 1000;
      await contract.setAssetTypeCost(1, cost);
      const [, assetCost] = await contract.getAsset(1);
      await expect(assetCost).to.equal(cost);
    });
  });

  describe("setCost", async () => {
    it("should throw if the caller it's not the owner of the contract", async () => {
      const transaction = contract.connect(signer).setAssetTypeCost(1, 100);
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should update current minting cost", async () => {
      const cost = 1000;
      await contract.setAssetTypeCost(1, cost);
      const [, assetCost] = await contract.getAsset(1);
      await expect(assetCost).to.equal(cost);
    });
  });

  describe("addAdmin", async () => {
    it("should throw if the caller it's not the owner of the contract", async () => {
      const transaction = contract.connect(signer).createAdmin(signer.address);
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should add an address to the admins list", async () => {
      await contract.createAdmin(signer.address);
      const [, enabled] = await contract.getAdmin(signer.address);
      await expect(enabled).to.equal(true);
      await contract.connect(signer).adminMint(signer.address, 1, 1);
      await expect(await contract.balanceOfType(signer.address, 1)).to.equal(1);
    });
    it("should know if address is not admin", async () => {
      const tx = contract.getAdmin(signer.address);
      await expect(tx).to.be.revertedWith("Admin not found");
    });
  });

  describe("removeAdmin", async () => {
    it("should throw if the caller it's not the owner of the contract", async () => {
      const transaction = contract
        .connect(signer)
        .setAdminEnabled(contractOwner.address, false);
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should remove an address form the admins list", async () => {
      await contract.createAdmin(signer.address);
      const [, enabled1] = await contract.getAdmin(signer.address);
      await expect(enabled1).to.equal(true);
      await contract.setAdminEnabled(signer.address, false);
      const [, enabled2] = await contract.getAdmin(signer.address);
      await expect(enabled2).to.equal(false);
      const transaction = contract
        .connect(signer)
        .adminMint(signer.address, 1, 1);
      await expect(transaction).to.be.revertedWith("Caller is not an admin");
    });
  });

  describe("URI", () => {
    it("should get URI", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 1);
      
      await signerContract.mint(1, 1);

      const uri = await contract.tokenURI(1);
      const metadata = JSON.parse(
        Buffer.from(uri.slice(29), "base64").toString("utf8")
      );

      await expect(metadata.name).to.equal("Hoodie");
      await expect(metadata.image).to.equal("1.png");
      await expect(metadata.animation_url).to.equal("1.mp4");
      await expect(metadata.external_url).to.equal("1");
    });
    it("should set URI", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 1);

      await signerContract.mint(1, 1);

      await contract.setImageBaseURI("ipfs://image/");
      await contract.setAnimationBaseURI("ipfs://animation/");
      await contract.setExternalBaseURI("ipfs://external/");
      const uri = await contract.tokenURI(1);
      const metadata = JSON.parse(
        Buffer.from(uri.slice(29), "base64").toString("utf8")
      );

      await expect(metadata.name).to.equal("Hoodie");
      await expect(metadata.image).to.equal("ipfs://image/1.png");
      await expect(metadata.animation_url).to.equal("ipfs://animation/1.mp4");
      await expect(metadata.external_url).to.equal("ipfs://external/1");
    });
    it("should set URI (again)", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 1);

      await signerContract.mint(1, 1);

      await contract.setImageBaseURI("ipfs://image/");
      await contract.setAnimationBaseURI("ipfs://animation/");
      await contract.setExternalBaseURI("ipfs://external/");
      const uri = await contract.tokenURI(1);
      const metadata = JSON.parse(
        Buffer.from(uri.slice(29), "base64").toString("utf8")
      );

      await expect(metadata.name).to.equal("Hoodie");
      await expect(metadata.image).to.equal("ipfs://image/1.png");
      await expect(metadata.animation_url).to.equal("ipfs://animation/1.mp4");
      await expect(metadata.external_url).to.equal("ipfs://external/1");

      await contract.setImageBaseURI("ipfs://image2/");
      await contract.setAnimationBaseURI("ipfs://animation2/");
      await contract.setExternalBaseURI("ipfs://external2/");
      const newUri = await contract.tokenURI(1);
      const newMetadata = JSON.parse(
        Buffer.from(newUri.slice(29), "base64").toString("utf8")
      );

      await expect(newMetadata.name).to.equal("Hoodie");
      await expect(newMetadata.image).to.equal("ipfs://image2/1.png");
      await expect(newMetadata.animation_url).to.equal(
        "ipfs://animation2/1.mp4"
      );
      await expect(newMetadata.external_url).to.equal("ipfs://external2/1");
    });
    it("should effect tokenURI", async () => {
      await tokenContract.createAdmin(contract.address);
      await tokenContract.award(signer.address, 1);

      await signerContract.mint(1, 1);

      await contract.setImageBaseURI("ipfs://image/");
      await contract.setAnimationBaseURI("ipfs://animation/");
      await contract.setExternalBaseURI("ipfs://external/");
      const tokenURI = await contract.tokenURI(1);
      const metadata = JSON.parse(
        Buffer.from(tokenURI.slice(29), "base64").toString("utf8")
      );

      await expect(metadata.name).to.equal("Hoodie");
      await expect(metadata.image).to.equal("ipfs://image/1.png");
      await expect(metadata.animation_url).to.equal("ipfs://animation/1.mp4");
      await expect(metadata.external_url).to.equal("ipfs://external/1");
    });
    it("should fail to update image uri if user (not owner)", async () => {
      const transaction = contract
        .connect(signer)
        .setImageBaseURI("ipfs://xyz/");
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should fail to update image uri if admin (not owner)", async () => {
      await contract.createAdmin(signer.address);
      const transaction = contract
        .connect(signer)
        .setImageBaseURI("ipfs://xyz/");
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should fail to update animation uri if user (not owner)", async () => {
      const transaction = contract
        .connect(signer)
        .setAnimationBaseURI("ipfs://xyz/");
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should fail to update animation uri if admin (not owner)", async () => {
      await contract.createAdmin(signer.address);
      const transaction = contract
        .connect(signer)
        .setAnimationBaseURI("ipfs://xyz/");
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should fail to update external uri if user (not owner)", async () => {
      const transaction = contract
        .connect(signer)
        .setExternalBaseURI("ipfs://xyz/");
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    it("should fail to update external uri if admin (not owner)", async () => {
      await contract.createAdmin(signer.address);
      const transaction = contract
        .connect(signer)
        .setExternalBaseURI("ipfs://xyz/");
      await expect(transaction).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("max count", () => {
    it("should get max count", async () => {
      const [, , , maxCount] = await contract.getAsset(1);
      await expect(maxCount).to.equal(2500);
    });
  });

  describe("gas reports", () => {
    it("add 500 url's", () => {});
  });
});
