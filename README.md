# ERC1155 BY pure Yul

## Basic Introduction

The repo implementats [EIP1155](https://eips.ethereum.org/EIPS/eip-1155) by pure YUI
1. Support functions
    * [✅]function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    * [✅]function safeBatchTransferFrom(address _from,address _to,uint256[] calldata _ids,uint256[] calldata _values,bytes calldata _data) external;
    * [✅]function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    * [✅]function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    * [✅]function setApprovalForAll(address _operator, bool _approved) external;
    * [✅]function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    * [✅]function mint(address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    * [✅]function burn(address from, uint256 _id, uint256 _value) external;
    * [✅]function batchBurn(address _to, uint256[] memory _ids, uint256[] memory _values) external;
    * [✅]function batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data) external;

2. Support Events
    * [✅]event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    * [✅]event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    * [✅]event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    * [✅]event URI(string _value, uint256 indexed _id);


## Test case
* [All test cases](TestCases.md)


## How to deal array(including string) in calldata or memory

1. When call other address's function, how to combine the calldata in current address' s memory
    * [BUILD CALLDATA IN MEMORY](buildCALLDATAInMemory.md)

2. How to store string,extract string,manage string in slot or memory.
    * [MBINE URI(string) IN YUL](URIOperation.md)


## Some tips

1. How to store mapping  TODO, check the approve ??
    (balance mapping)[https://github.com/sodexx7/yui_erc1155/blob/6965795363e69794d6787d9d27a3ce58fd0088c2/yul/ERC1155_YUI.yul#L383]

1. memory conflict



2. how to store mapping
3. more check should do by myslef, such as param type check

4. // address format: 0x + "0"*20+"f"*12 address check methodss

5. The necessay using fuzzing 


other edge cases
6. array empty not check

7.  fuzzing test is necessary for helping me find many hidden bugs, such as the empty array

8. 
验证address的方法
1 chesum solidity
2 Yui demo code

9. Many feature Yui should do by myself, for the solitiy perhaps do more check, such as params type check

## lacks

1. No rights check
    1. Burn should check the owner can burn
    2. setApprovalForAll    should check the caller is owner
    3

2. Test one function, build array param, that not fit the requirements

3. No supports Interface

4. overflow Check while balance changed

5.


## References
    1. Test cases https://github.com/transmissions11/solmate/blob/main/src/test/ERC1155.t.sol

    2. https://github.com/khegeman/y-files/blob/main/src/Events.sol
        https://codebeautify.org/string-hex-converter ??


references: how solidity manipulate memory. 
https://docs.soliditylang.org/en/latest/internals/layout_in_memory.html#layout-in-memory


    3. 
        /**
            reference:
            // operate memory array.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Arrays.sol
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol
        // https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol

tood
1. checkArray build bytesCode calldata