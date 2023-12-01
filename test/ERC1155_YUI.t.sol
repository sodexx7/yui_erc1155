// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "./tokens/ERC1155TokenReceiver.sol";

// todo basic funtions 
interface ERC1155_YUI {

    // The first funtion should check
    // function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external; confirm the function is right?

    function mint(address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data) external;



    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

}

// different situations involved with ERC1155TokenReceiver  Normal/Revert/WrongReturnData/NonERC1155Recipient
contract ERC1155Recipient is ERC1155TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    uint256 public amount;
    bytes public mintData;

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
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
        batchOperator = _operator;
        batchFrom = _from;
        _batchIds = _ids;
        _batchAmounts = _amounts;
        batchData = _data;

        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract RevertingERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector)));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector)));
    }
}

contract WrongReturnDataERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return 0xCAFEBEEF;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC1155Recipient {}

//  All test cases
contract ERC1155_YUITest is DSTestPlus {

   
    YulDeployer yulDeployer = new YulDeployer();

    ERC1155_YUI token;

    // todo
    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256)) public userTransferOrBurnAmounts;

    function setUp() public {
        token = ERC1155_YUI(yulDeployer.deployContract("ERC1155_YUI"));
    }

    /************************************************************************* SINGLE ****************************************************************************/
    
    /////////////////////////////////////////////////////////////////////////// MINT ///////////////////////////////////////////////////////////////////////////// 

    // DOING faliure situations check
    /*** doing

        2 metatask ids how to dealwith. 
            https://eips.ethereum.org/EIPS/eip-1155#erc-1155-metadata-uri-json-schema
        3 familar with YUI. Udemy Course


    todo
    1) more test cases arrange
    2) basci Yui functions done

    
     */
    function testMintToEOA() public {
        token.mint(address(0xBEEF), 1337, 1, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 1);
    }

    function testMintToEOA(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory mintData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.mint(to, id, amount, mintData);

        assertEq(token.balanceOf(to, id), amount);
    }


    // function testMintToERC1155Recipient() public {
    //     ERC1155Recipient to = new ERC1155Recipient();

    //     token.mint(address(to), 1337, 1, "testing 123");

    //     assertEq(token.balanceOf(address(to), 1337), 1);

    //     assertEq(to.operator(), address(this));
    //     assertEq(to.from(), address(0));
    //     assertEq(to.id(), 1337);
    //     assertBytesEq(to.mintData(), "testing 123");
    // }

    // function testMintToERC1155Recipient(
    //     uint256 id,
    //     uint256 amount,
    //     bytes memory mintData
    // ) public {
    //     ERC1155Recipient to = new ERC1155Recipient();

    //     token.mint(address(to), id, amount, mintData);

    //     assertEq(token.balanceOf(address(to), id), amount);

    //     assertEq(to.operator(), address(this));
    //     assertEq(to.from(), address(0));
    //     assertEq(to.id(), id);
    //     assertBytesEq(to.mintData(), mintData);
    // }


    //////////////////////////////////////////////////////////////// TRANSFER ///////////////////////////////////////////////////////////////////////////// 

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromToEOA(
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

        token.mint(from, id, mintAmount, mintData);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id, transferAmount, transferData);

        if (to == from) {
            assertEq(token.balanceOf(to, id), mintAmount);
        } else {
            assertEq(token.balanceOf(to, id), transferAmount);
            assertEq(token.balanceOf(from, id), mintAmount - transferAmount);
        }
    }



    /************************************************************************* BATCH ****************************************************************************/
    
    /////////////////////////////////////////////////////////////////////////// MINT ///////////////////////////////////////////////////////////////////////////// 


    function testBatchMintToEOA() public {
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

        token.batchMint(address(0xBEEF), ids, amounts, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 300);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 400);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 500);
    }
    

     function testBatchMintToEOA(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[to][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[to][id] += mintAmount;
        }

        token.batchMint(to, normalizedIds, normalizedAmounts, mintData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(to, id), userMintAmounts[to][id]);
        }
    }

    // function testBatchMintToERC1155Recipient() public {
    //     ERC1155Recipient to = new ERC1155Recipient();

    //     uint256[] memory ids = new uint256[](5);
    //     ids[0] = 1337;
    //     ids[1] = 1338;
    //     ids[2] = 1339;
    //     ids[3] = 1340;
    //     ids[4] = 1341;

    //     uint256[] memory amounts = new uint256[](5);
    //     amounts[0] = 100;
    //     amounts[1] = 200;
    //     amounts[2] = 300;
    //     amounts[3] = 400;
    //     amounts[4] = 500;

    //     token.batchMint(address(to), ids, amounts, "testing 123");

    //     assertEq(to.batchOperator(), address(this));
    //     assertEq(to.batchFrom(), address(0));
    //     assertUintArrayEq(to.batchIds(), ids);
    //     assertUintArrayEq(to.batchAmounts(), amounts);
    //     assertBytesEq(to.batchData(), "testing 123");

    //     assertEq(token.balanceOf(address(to), 1337), 100);
    //     assertEq(token.balanceOf(address(to), 1338), 200);
    //     assertEq(token.balanceOf(address(to), 1339), 300);
    //     assertEq(token.balanceOf(address(to), 1340), 400);
    //     assertEq(token.balanceOf(address(to), 1341), 500);
    // }

    // function testBatchMintToERC1155Recipient(
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory mintData
    // ) public {
    //     ERC1155Recipient to = new ERC1155Recipient();

    //     uint256 minLength = min2(ids.length, amounts.length);

    //     uint256[] memory normalizedIds = new uint256[](minLength);
    //     uint256[] memory normalizedAmounts = new uint256[](minLength);

    //     for (uint256 i = 0; i < minLength; i++) {
    //         uint256 id = ids[i];

    //         uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

    //         uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

    //         normalizedIds[i] = id;
    //         normalizedAmounts[i] = mintAmount;

    //         userMintAmounts[address(to)][id] += mintAmount;
    //     }

    //     token.batchMint(address(to), normalizedIds, normalizedAmounts, mintData);

    //     assertEq(to.batchOperator(), address(this));
    //     assertEq(to.batchFrom(), address(0));
    //     assertUintArrayEq(to.batchIds(), normalizedIds);
    //     assertUintArrayEq(to.batchAmounts(), normalizedAmounts);
    //     assertBytesEq(to.batchData(), mintData);

    //     for (uint256 i = 0; i < normalizedIds.length; i++) {
    //         uint256 id = normalizedIds[i];

    //         assertEq(token.balanceOf(address(to), id), userMintAmounts[address(to)][id]);
    //     }
    // }
    
    
    //////////////////////////////////////////////////////////////// TRANSFER ///////////////////////////////////////////////////////////////////////////// 
    function testSafeBatchTransferFromToEOA() public {
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
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testSafeBatchTransferFromToEOA(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        address from = address(0xABCD);

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

        token.safeBatchTransferFrom(from, to, normalizedIds, normalizedTransferAmounts, transferData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(address(to), id), userTransferOrBurnAmounts[from][id]);
            assertEq(token.balanceOf(from, id), userMintAmounts[from][id] - userTransferOrBurnAmounts[from][id]);
        }
    }

    /************************************************************************* APPROVE ****************************************************************************/
    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertBoolEq(token.isApprovedForAll(address(this), to), approved);
    }


    // todo

    // doing orginazing the test cases actually test functions


    /**
        how to make the init balance
        test cases list
     */
    // 
    // doing 
    //  _mint(to, id, amount, data);



    // test funtions
    /**
    1) create the contract.
            What's the init balance? how to deal with it? in the constructor.
    
    2) mint/burn
        at least some balance?


    3)
    
    
     */
    

    /**
    // todo
    DOING: mint，burn/(single/Batch)
           
         1)  different test categarios list almost/  Safe  Rules or scenarios check  done
         2)  metadata check ,how to generate  id ? 

            organize test cases more cleanly

             mint and burn check
              test tools funtions to dig? max3? bond?



     
    1: test funtions 
        1) reference: ERC1155.t.sol
        2) prepare 
            1: how to mint?

            mint/burn(burn/destroy operations are specialized transfers)
            
            create: from:0x00 // burn: to:0x00
            values? how to set token? Ids????


            the init balance?
                mint burn

            Minting/creating and burning/destroying rules:

                TransferSingle
                    1) 
                    To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from 0x0 to 0x0, with the token creator as _operator, and a _value of 0.    


                event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);


            the related events:
                event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
                event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

                 minting/creating tokens: the `_from` argument MUST be set to `0x0`
                 burning/destroying tokens, the `_to` argument MUST be set to `0x0`

            how to set the uri?

        3) core test funtions
            mint/burn(burn/destroy operations are specialized transfers)



            safeTransferFrom
            safeBatchTransferFrom
            balanceOf
            balanceOfBatch
            setApprovalForAll
            isApprovedForAll

            faliue scenarios test

            all different types of falure scenarios  TODO
            according to the rules, list all the possible test funtion types.
            https://eips.ethereum.org/EIPS/eip-1155#safe-transfer-rules




            event:
                TransferSingle
                TransferBatch
                ApprovalForAll
                URI
        4) some notices
            1) batch mint/transfer vs signel mint or transfer
            2) balance check
            3) how to calculate the circulating supply?
                    The total value transferred from address 0x0 minus the total value transferred to 0x0 observed via the TransferSingle and TransferBatch events MAY be used by clients and exchanges to determine the “circulating supply” for a given token ID.
                    (Minting/creating and burning/destroying rules)
                
            4) test to EOA/ Smart contract. Smart contract foucus on the Scenarios(https://eips.ethereum.org/EIPS/eip-1155)
            5) testMintToERC1155Recipient
                the blew params:
                address public operator;
                address public from;
                uint256 public id;
                uint256 public amount;
                bytes public mintData;

            6) how to test only NFT721 OR erc20

        5) diffcult

            testBatchMintToEOA(test/ERC1155.t.sol)
                1)operate array in memory
                2) 

        6) ERC1155TokenReceiver also implement? By Yui
            solidity abstact how to implement by the YUI language?
            

     */
    
}


/**
todo
 1) interface basic funtions 
 
 2)
 ``` when emit the below events?

- [ ]  **`event** TransferSingle(**address** **indexed** _operator, **address** **indexed** _from, **address** **indexed** _to, **uint256** _id, **uint256** _value);`
- [ ]  **`event** TransferBatch(**address** **indexed** _operator, **address** **indexed** _from, **address** **indexed** _to, **uint256**[] _ids, **uint256**[] _values);`
- [ ]  **`event** ApprovalForAll(**address** **indexed** _owner, **address** **indexed** _operator, **bool** _approved);`
- [ ]  **`event** URI(**string** _value, **uint256** **indexed** _id);`
 
 ```

 3) doing 
    test cases summary, especially for the failure types. doing

    todo: init mint/burn



 */




