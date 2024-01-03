# ERC1155 by pure Yul

## Basic Introduction

The repo implementats [EIP1155](https://eips.ethereum.org/EIPS/eip-1155) by pure YUI
1. Support functions
    * [✅]function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    * [✅]function safeBatchTransferFrom(address _from,address _to,uint256[] calldata _ids,uint256[] calldata _values,bytes calldata _data) external;
    * [✅]function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    * [✅]function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    * [✅]function setApprovalForAll(address _operator, bool _approved) external;
    * [✅]function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    * *below just for test*
    * [✅]function mint(address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    * [✅]function burn(address from, uint256 _id, uint256 _value) external;
    * [✅]function batchBurn(address _to, uint256[] memory _ids, uint256[] memory _values) external;
    * [✅]function batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data) external;
    * *URI related*
    * [✅]function setURI(uint256 tokenId, string memory tokenURI)
    * [✅]function getURI() external returns (string memory);
    * [✅]function updateURIWithTokenId(uint256 id,string memory URI) external;

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
    * [COMBINE URI(string) IN YUL](URIOperation.md)


## Some tips

1. Memory usage
    * There maybe some memory conflict, each time involving using memory beginning from 0x.
2. For the mapping data structure, like token's balance, token's URI. same as solidity

3. If the smart contract was written by pure YUL. the foundry can't test the function params if the param not fit the corrospending type

4. address check methods  0x + "0"*20+"f"*12  vs checksum() ???

5. fuzzing test is necessary for helping me find many hidden bugs, such as the empty array

6. Although there are huge test cases, some edge case also missing. such as rights check

7. The batch means batch transfer Id with its values, not transfer to many accounts.

8. For the function params, no matter the memory or calldata, calldata must have data.

9. Hex strings in YUL, hex"616263" 

## Lacks

1. No rights check
    1. Burn should check the owner can burn
    2. setApprovalForAll    should check the caller is owner
    3

2. overflow Check while balance changed

2. Test one function, build array param, that not fit the requirements

3. No supports Interface

5. setURI/updateURIWithTokenId not check the suffix. 

6. operatorApprovalStorageOffset not use

## Questions
1. For changing the URI no matter for the basic URI or the token's URI, as URI including many features(name,decimals), Is that bring potential problems?

2. how to comptable with current ERC20 or ERC721?
* It seems the adoption with ERC20 or ERC721 doesn't widely apply.
   

## References
1. Test cases https://github.com/transmissions11/solmate/blob/main/src/test/ERC1155.t.sol
2. [openzeppelin ERC1155](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol)
2. https://github.com/khegeman/y-files/blob/main/src/Events.sol
3. https://codebeautify.org/string-hex-converter
4. references: how solidity manipulate memory. 
    * https://docs.soliditylang.org/en/latest/internals/layout_in_memory.html#layout-in-memory
5. Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    ```solidity
    /**
        * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
        */
        //  reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/932fddf69a699a9a80fd2396fd1a2ab91cdda123/contracts/utils/Strings.sol#L65 ignore 0x
        bytes16 private constant HEX_DIGITS = "0123456789abcdef";

        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
            uint256 localValue = value;
            bytes memory buffer = new bytes(2 * length);
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i - 2] = HEX_DIGITS[localValue & 0xf];
                localValue >>= 4;
            }

            return string(buffer);
        }
    ```
6. the use for `forge inspect ERC1155_YUI storageLayout`