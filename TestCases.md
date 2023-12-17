# TEST_LIST

## Transfer Test Cases

* For the transfer/mint function, each test case will fall in one of the below criterias(4 different situations)

1.  Single vs Batch
2.  (onERC1155Received check)


|       criterias             | (onERC1155Received check) | Batch/Single |
| ----------------------------| --------------------------| ------------ |


## Test cases outline

0. Main functions
    1. safeTransferFrom
    2. safeBatchTransferFrom
    3. balanceOf
    4. balanceOfBatch
    5. setApprovalForAll
    6. isApprovedForAll

1. **mint/ safeTransfer(including fuzzing)** 
* Normal cases
    1. Single/Batch
    2. (onERC1155Received check) 
* Expection cases                  
    * ERC1155Recipient Expections
        1. RevertingERC1155Recipient
        2. NonERC1155Recipient
        3. WrongReturnDataERC1155Recipient    
    * To Zero Address  
    * InsufficientBalance  

2. **burn(including fuzzing)**
    *  Normal cases
        1. Single/Batch
    * Expection cases
        1. InsufficientBalance
        2. ArrayLengthMismatch
3. **Balance(including fuzzing)**
    * Normal cases
        1. Single/Batch
            DOING Singal not cover
    * Expection cases
        1. ArrayMismatch
4. **Approve(including fuzzing)** 
    1. testApproveAll

5. **Event Test(including fuzzing,exclude URI)** 
    * related Events
        1. event TransferSingle
        2. event ApprovalForAll
        3. event TransferBatch
    * My test scenarios, more scenarios can be add, but I think the below cases have covert every corcner   
        * testEventMintToEOA
        * testEventMintToERC1155Recipient
        * testEventBurn
        * testEventSafeTransferFromToEOA
        * testEventSafeTransferFromToERC1155Recipient

5. **URI Test** 
    * testSetURI 
    * testEmitURI when mint one token, emit this event

 
## Test Cases

**SINGLE**

**MINT 12**

- [✅]  testMintToEOA (No arguments / Fuzzing test )  event
- [✅]  testMintToERC1155Recipient (No arguments / Fuzzing ) event

- [✅]  testFailMintToZero(No arguments / Fuzzing test )
- [✅]  testFailMintToNonERC155Recipient (No arguments / Fuzzing test )
- [✅]  testFailMintToRevertingERC155Recipient (No arguments / Fuzzing test )
- [✅]  testFailMintToWrongReturnDataERC155Recipient (No arguments / Fuzzing test )

**Burn 4**

- [✅]  testBurn (No arguments / Fuzzing test )
- [✅]  testFailBurnInsufficientBalance (No arguments / Fuzzing test )

**Transfer  18**

- [✅]  testSafeTransferFromToEOA(No arguments / Fuzzing test ) all done event
- [✅]  testSafeTransferFromToERC1155Recipient (No arguments / Fuzzing test ) event
- [✅]  testSafeTransferFromSelf(No arguments / Fuzzing test )

- [✅]  testFailSafeTransferFromToZero (No arguments / Fuzzing test )
- [✅]  testFailSafeTransferFromToNonERC155Recipient (No arguments / Fuzzing test )
- [✅]  testFailSafeTransferFromInsufficientBalance() (No arguments / Fuzzing test )
- [✅]  testFailSafeTransferFromSelfInsufficientBalance() (No arguments / Fuzzing test )
- [✅]  testFailSafeTransferFromToRevertingERC1155Recipient (No arguments / Fuzzing test )
- [✅]  testFailSafeTransferFromToWrongReturnDataERC1155Recipient  (No arguments / Fuzzing test )

**Balance**  testApproveAll also covered?

- [ ]  Most of other test cases have covered  balanceOf() function
- [ ]  

Approve testBatch also covered?

**BATCH**

**MINT 14**

- [✅]  testBatchMintToEOA (No arguments / Fuzzing test ) all done
- [✅]  testBatchMintToERC1155Recipient (No arguments / Fuzzing test )

- [✅]  testFailBatchMintToZero (No arguments / Fuzzing test )
- [✅]  testFailBatchMintToNonERC1155Recipient  (No arguments / Fuzzing test )
- [✅]  testFailBatchMintToRevertingERC1155Recipient (No arguments / Fuzzing test )
- [✅]  testFailBatchMintToWrongReturnDataERC1155Recipient (No arguments / Fuzzing test )
- [✅]  testFailBatchMintWithArrayMismatch (No arguments / Fuzzing test )

Burn 6

- [✅]  testBatchBurn(No arguments / Fuzzing test )

- [✅]  testFailBatchBurnInsufficientBalance  (No arguments / Fuzzing test )
- [✅]  testFailBatchBurnWithArrayLengthMismatch (No arguments / Fuzzing test )

Transfer16

- [✅]  testSafeBatchTransferFromToEOA (No arguments / Fuzzing test ) event
- [✅]  testSafeBatchTransferFromToERC1155Recipient (No arguments / Fuzzing test )  event done

- [✅]  testFailSafeBatchTransferInsufficientBalance (No arguments / Fuzzing test )
- [✅]  testFailSafeBatchTransferFromToZero(No arguments / Fuzzing test )
- [✅]  testFailSafeBatchTransferFromToNonERC1155Recipient (No arguments / Fuzzing test )
- [✅]  testFailSafeBatchTransferFromToRevertingERC1155Recipient (No arguments / Fuzzing test )
- [✅]  testFailSafeBatchTransferFromToWrongReturnDataERC1155Recipient (No arguments / Fuzzing test )
- [✅]  testFailSafeBatchTransferFromWithArrayLengthMismatch (No arguments / Fuzzing test )

**Balance 4** 

- [✅]  testBatchBalanceOf()  (No arguments / Fuzzing test )  

- [✅]  testFailBalanceOfBatchWithArrayMismatch (No arguments / Fuzzing test )

**Approve 2**

- [✅]  testApproveAll  (No arguments / Fuzzing test ) all done

**EVENT 10**

- [✅]  testEventMintToEOA()   (No arguments / Fuzzing test ) 
- [✅]  testEventMintToERC1155Recipient()   (No arguments / Fuzzing test ) 
- [✅]  testEventBurn()   (No arguments / Fuzzing test ) 
- [✅]  testEventSafeTransferFromToEOA()   (No arguments / Fuzzing test ) 
- [✅]  testEventSafeTransferFromToERC1155Recipient()   (No arguments / Fuzzing test ) 
 
**URI** 4
- [✅]  testSetURI()   (No arguments / Fuzzing test ) 
- [✅]  testEmitURI()   (No arguments / Fuzzing test )  event test, when mint one token, emit the event


94 test case

* Burn 10 event 2 ok
* mint 26 event 5 ok
* Transfer 34 event 7
* Balance 4 ok
* Approve 2
* URI 4



## quesitons
1. The test cases's numbers seems very huge. Are there some tools can manage that?


## Others
1. Customer error can see  testFailSafeBatchTransferFromToZero


