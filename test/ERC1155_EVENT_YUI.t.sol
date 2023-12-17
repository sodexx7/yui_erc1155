// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "./tokens/ERC1155TokenReceiver.sol";

interface ERC1155_YUI {

    function mint(address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function burn(address from, uint256 _id, uint256 _value) external;

    function batchBurn(address _to, uint256[] memory _ids, uint256[] memory _values) external;
    function batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data) external;

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  
}

contract ERC1155Recipient is ERC1155TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    uint256 public amount;
    bytes public mintData;

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data)
        public
        override
        returns (bytes4)
    {
        console.log("onERC1155Received enter");
        operator = _operator;
        from = _from;
        id = _id;
        amount = _amount;
        mintData = _data;

        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    address public batchOperator;
    address public batchFrom;
    uint256[] internal _batchIds;
    uint256[] internal _batchAmounts;
    bytes public batchData;

    function batchIds() external view returns (uint256[] memory) {
        return _batchIds;
    }

    function batchAmounts() external view returns (uint256[] memory) {
        return _batchAmounts;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external override returns (bytes4) {
        console.log("onERC1155BatchReceived enter");
        batchOperator = _operator;
        batchFrom = _from;
        _batchIds = _ids;
        _batchAmounts = _amounts;
        batchData = _data;

        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract ERC1155_YUITest is DSTestPlus {

    YulDeployer yulDeployer = new YulDeployer();

    ERC1155_YUI token;

    // todo
    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256)) public userTransferOrBurnAmounts;

    function setUp() public {
        token = ERC1155_YUI(yulDeployer.deployContract("ERC1155_YUI"));
    }


    /////////////////////////////////////////////////////////////////////////// EVENTS /////////////////////////////////////////////////////////////////////////////

    //  all transfer scenarios should emit the event
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    function testEventMintToEOA() public {
        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), address(0xBEEF), 1337, 1);
        token.mint(address(0xBEEF), 1337, 1, "");
    }

    function testEventMintToEOA(address to, uint256 id, uint256 amount, bytes memory mintData) public {
        if (to == address(0)) to = address(0xBEEF);
        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), to, id, amount);
        token.mint(to, id, amount, mintData);
    }

    function testEventMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), address(to), 1337, 1);
        token.mint(address(to), 1337, 1, "testing 123");
    }

    function testEventMintToERC1155Recipient(uint256 id, uint256 amount, bytes memory mintData) public {
        ERC1155Recipient to = new ERC1155Recipient();
        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), address(to), id, amount);
        token.mint(address(to), id, amount, mintData);
    }

    function testEventBurn() public {
        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), address(0xBEEF), 1337, 100);
        token.mint(address(0xBEEF), 1337, 100, "");

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0xBEEF), address(0), 1337, 70);
        token.burn(address(0xBEEF), 1337, 70);
    }

    function testEventBurn(address to, uint256 id, uint256 mintAmount, bytes memory mintData, uint256 burnAmount)
        public
    {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        burnAmount = bound(burnAmount, 0, mintAmount);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), to, id, mintAmount);
        token.mint(to, id, mintAmount, mintData);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), to, address(0), id, burnAmount);
        token.burn(to, id, burnAmount);
    }

    function testEventSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), from, 1337, 100);
        token.mint(from, 1337, 100, "");

        hevm.prank(from);

        hevm.expectEmit(true, true, false, true);
        emit ApprovalForAll(from, address(this), true);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), from, address(0xBEEF), 1337, 70);
        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");
    }

    function testEventSafeTransferFromToEOA(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        address from = address(0xABCD);

        hevm.expectEmit(true, true, false, true);
        emit TransferSingle(address(this), address(0), from, id, mintAmount);
        token.mint(from, id, mintAmount, mintData);

        hevm.prank(from);

        hevm.expectEmit(true, true, true, false);
        emit ApprovalForAll(from, address(this), true);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), from, to, id, transferAmount);
        token.safeTransferFrom(from, to, id, transferAmount, transferData);
    }

    function testEventSafeTransferFromToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        hevm.expectEmit(true, true, false, true);
        emit TransferSingle(address(this), address(0), from, 1337, 100);
        token.mint(from, 1337, 100, "");

        hevm.prank(from);
        hevm.expectEmit(true, true, true, false);
        emit ApprovalForAll(from, address(this), true);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), from, address(to), 1337, 70);
        token.safeTransferFrom(from, address(to), 1337, 70, "testing 123");
    }

    function testEventSafeTransferFromToERC1155Recipient(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        bytes memory transferData
    ) public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        transferAmount = bound(transferAmount, 0, mintAmount);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), from, id, mintAmount);
        token.mint(from, id, mintAmount, mintData);

        hevm.prank(from);
        hevm.expectEmit(true, true, true, true);
        emit ApprovalForAll(from, address(this), true);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), from, address(to), id, transferAmount);
        token.safeTransferFrom(from, address(to), id, transferAmount, transferData);
    }


    /**
     * Batch ***************************************************************************
     */

    // event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    function testEventBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        hevm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), address(0), address(0xBEEF), ids, amounts);
        token.batchMint(address(0xBEEF), ids, amounts, "");
    }

    function testEventSafeBatchTransferFromToEOA() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        hevm.prank(from);
        hevm.expectEmit(true, true, true, true);
        emit ApprovalForAll(from, address(this), true);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), from, address(0xBEEF), ids, transferAmounts);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testEventSafeBatchTransferFromToERC1155Recipient() public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), from, address(to), ids, transferAmounts);
        token.safeBatchTransferFrom(from, address(to), ids, transferAmounts, "testing 123");
    }

    function testEventSafeBatchTransferFromToERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
            userTransferOrBurnAmounts[from][id] += transferAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        hevm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), from, address(to), normalizedIds, normalizedTransferAmounts);
        token.safeBatchTransferFrom(from, address(to), normalizedIds, normalizedTransferAmounts, transferData);
    }

}
