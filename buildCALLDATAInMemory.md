
# BUILD CALLDATA IN MEMORY 

## Get Array from calldata

### How to get the array's postion in calldata?

* get array's postion in calldata(should add 0x04)
* calldataload(add(4, mul(offset, 0x20)))

### How to calculate the array's length in calldata?

* data_length := calldataload(add(4,data_length_pos))

* array's length = data_length+0x20(length_pos)

* code implementation [CopyArrayToMemory](https://github.com/sodexx7/yui_erc1155/blob/b30acfcb2b83749b2f6f360c39443f99eafaecbd/yul/ERC1155_YUI.yul#L291)


### How to get the bytes's length in calldata?

* Because bytes's data is tightly encode, Calculate its length based on my code formula

* [bytes's length code implementation](https://github.com/sodexx7/yui_erc1155/blob/b30acfcb2b83749b2f6f360c39443f99eafaecbd/yul/ERC1155_YUI.yul#L326)


**related test case: [testBatchMintToERC1155Recipient()](https://github.com/sodexx7/yui_erc1155/blob/b30acfcb2b83749b2f6f360c39443f99eafaecbd/test/ERC1155_YUI.t.sol#L386) The below ara the test case's data**
```M

0xb48ab8b6 batchMint				     									variable			pos in calldata				
0000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b			to address			0x00
0000000000000000000000000000000000000000000000000000000000000080			ids pos				0x04
0000000000000000000000000000000000000000000000000000000000000140			values pos 			0x24
0000000000000000000000000000000000000000000000000000000000000200			bytes  pos			0x44
0000000000000000000000000000000000000000000000000000000000000005			ids length								   data_length, when want to get the pos, should add 4
0000000000000000000000000000000000000000000000000000000000000539			ids value
000000000000000000000000000000000000000000000000000000000000053a			ids value
000000000000000000000000000000000000000000000000000000000000053b			ids value
000000000000000000000000000000000000000000000000000000000000053c			ids value
000000000000000000000000000000000000000000000000000000000000053d			ids value
0000000000000000000000000000000000000000000000000000000000000005			values length 
0000000000000000000000000000000000000000000000000000000000000064			values value
00000000000000000000000000000000000000000000000000000000000000c8			values value
000000000000000000000000000000000000000000000000000000000000012c			values value
0000000000000000000000000000000000000000000000000000000000000190			values value
00000000000000000000000000000000000000000000000000000000000001f4			values value
000000000000000000000000000000000000000000000000000000000000000b			bytes pos           0x200                  0x0b<0x20, bytes_size_0x20 = 0x40 
74657374696e6720313233000000000000000000000000000000000000000000			bytes value


```

## How to build CALL DATA in memory


## My memory layout explanation

```M
    Memory postion              variables
    0x00->0x04                  function Signature
    0x04->0x24                  opertor(caller())
    0x24->0x44                  from address
    0x44->0xa0                  ids pos(0x84+0x20)                                          ||| just store id if id is uint                         
    0x64->value_pos             value pos(should based on the actual size of the ids )      ||| just store value if value is uint
    0x84->bytes_pos             bytes pos(should based on the actual size of ids, values )  
    
    0xa0->                      ids'size           
    ....                        ids'each value

    value_pos->                 value's size  
    ...                         values'each value

    bytes_pos->                 bytes's size
    ...                         values'each value
```

## Actual data as below 
* related test case [testBatchMintToERC1155Recipient()](https://github.com/sodexx7/yui_erc1155/blob/b30acfcb2b83749b2f6f360c39443f99eafaecbd/test/ERC1155_YUI.t.sol#L386)
* The below data will as the Call data when calling the onERC1155BatchReceived() on the to address. 
* So the below layout obey the EVM calldata conversations.

```m
0xbc197c81													       pos_no_fun    actual_pos      variable
0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496        0x00     0x04			 operator
0000000000000000000000000000000000000000000000000000000000000000        0x20     0x24			 from
00000000000000000000000000000000000000000000000000000000000000a0        0x40     0x44			 ids_position        	should calcualte(0xa4)
0000000000000000000000000000000000000000000000000000000000000160        0x60     0x64            values_position		should calcualte (0xa4 + ids_size)
0000000000000000000000000000000000000000000000000000000000000220		0x80	 0x84		     bytes_pos  			should calcualte (0xa4 + ids_value + values_size)	

0000000000000000000000000000000000000000000000000000000000000005		0xa0	 0xa4			 ids_length_pos			
0000000000000000000000000000000000000000000000000000000000000539                 0xc4             
000000000000000000000000000000000000000000000000000000000000053a			     0xe4
000000000000000000000000000000000000000000000000000000000000053b				 0x104	
000000000000000000000000000000000000000000000000000000000000053c				 0x124
000000000000000000000000000000000000000000000000000000000000053d           		 0x144

0000000000000000000000000000000000000000000000000000000000000005				 0x164           value_length_pos	
0000000000000000000000000000000000000000000000000000000000000064
00000000000000000000000000000000000000000000000000000000000000c8
000000000000000000000000000000000000000000000000000000000000012c
0000000000000000000000000000000000000000000000000000000000000190
00000000000000000000000000000000000000000000000000000000000001f4
																				 
000000000000000000000000000000000000000000000000000000000000000b   				 0x224           bytes_pos
74657374696e6720313233000000000000000000000000000000000000000000


```

### How to Calculate the array's pos in memory according to above layout?
1. Based on the param's order, calculating which memory's pos will store the array's length pos. Such as ids is the third params, 0x04+0x20+0x20=0x44. 0x44 store the id's length pos
2. Based on how many arguments following this param, calculate the param's length postion, Such as there are 2 params(values,bytes) following ids, So 0x44+0x20+0x20+0x20=0xa0 will the ids'length pos. As **ids_length_pos** shows.


### How to store the array's data in memory according to above layout?
1. Get the array's length pos in memory, which store the array's length
2. Following the array's length, store all array's  value. 


[related code implementation-buildCalldataInMem](https://github.com/sodexx7/yui_erc1155/blob/b30acfcb2b83749b2f6f360c39443f99eafaecbd/yul/ERC1155_YUI.yul#L238)




