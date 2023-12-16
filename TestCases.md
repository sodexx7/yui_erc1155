# TEST_LIST

**CHECK CRITERIAS (each test case will fall in one of four types)**

1.  Contract types(EOA VS  Smart Contract)
2.  Single vs Batch


| (onERC1155Received check) | Single | Batch |
| --------------------------| ------ | ----- |
|           EOA             |        |       |
|       Smart Contract      |        |       |

The functions involved with the ERC1155

1. safeTransferFrom
2. safeBatchTransferFrom
3. balanceOf
4. balanceOfBatch
5. setApprovalForAll
6. isApprovedForAll

75  test cases

ERC1155TokenReceiver check(/Normal/)

ERC1155TokenReceiver(Reverting/WrongReturnData/NonERC155Recipient/)

EOA

**SINGLE 34**

current:  No arguments

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

- [ ]  
- [ ]  

Approve testBatch also covered?

**BATCH**

**MINT 14**

- [✅]  testBatchMintToEOA (No arguments / Fuzzing test ) all done
- [✅]  testBatchMintToERC1155Recipient (No arguments / Fuzzing test )
- [ ]  

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

- [✅]  testBatchBalanceOf()  (No arguments / Fuzzing test )  ?? which covered signal situation?

- [✅]  testFailBalanceOfBatchWithArrayMismatch (No arguments / Fuzzing test )

**Approve 2**

- [✅]  testApproveAll  (No arguments / Fuzzing test ) all done

current 76(? need to check again all test cases) 

(No arguments / Fuzzing test )   Fuzzing test  for fuzzing test

**EVENT**

URI

testEmitURI

questions

- no balanceOf test
- 