# COMBINE URI(string) IN YUL

## Problem and how to implement it

1. The demands originates from the [EIP155](https://eips.ethereum.org/EIPS/eip-1155#metadata) how to deal with the URI.
    
    * Firstly should store this format URI onchain https://token-cdn-domain/{id}.json, which can be taken as the basicURI. All token's URI can based on it.
    * If one token's URI has changed, should emit ```event URI(string _value, uint256 indexed _id)```, _value is the this token's URI

2. How to setURI and how to get the URI in my code?
    * ```function setURI(string memory URI) external;``` set the basicURI , whose suffix should ends with .json
    * ```function getURI() external returns (string memory);``` will get the basicURI
    * ```function updateURIWithTokenId(uint256 id,string memory URI) external;```, set the token's URI meanwhile emitting ```event URI(string _value, uint256 indexed _id)```

## The details of implementation

1. ```function setURI(string memory URI) external;```
    * the URI's slot's default value is 2.
    * The different store mechiniasm which depend on the whether the URI's length is greater 0x19 bytes or not 
        * if the URI's length is less or equal 0x19 bytes. store the value in the 2th slot
            ```M
                "https://cdn-domain/{id}.json"

                0x68747470733a2f2f63646e2d646f6d61696e2f7b69647d2e6a736f6e00000038
                  |******************************************************|      ||
                          the actual value                                      the length =  28*2 = 56(0x38)
            ```
            
        if the URI's length is greater than 0x19, 2th slot stil store the length, but store the actual value in the calculated postion.

             ```M
               https://aaaabcdn-domain/{id}.json
               
               2th-slot
               0x0000000000000000000000000000000000000000000000000000000000000043
                                                                               ||
                                                                              the length =  33*2+1 = 56(0x43)

              Calculated postions
              first pos 
                keccak256(URI's slot)
                0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace slot-key
                0x68747470733a2f2f616161616263646e2d646f6d61696e2f7b69647d2e6a736f slot-value
              
              following pos(previous slot +1) 
                0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5acf  slot-key
                0x6e00000000000000000000000000000000000000000000000000000000000000  slot-value
            ```
        [code implementation](https://github.com/sodexx7/yui_erc1155/blob/0a924a78cf1f87f43b5645fa19f200fc31d16cd0/yul/ERC1155_YUI.yul#L434)  
        * Reference: https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#bytes-and-string 


2. ```function getURI() external returns (string memory);```
     * just according to the different URI's length, build the new string in memory
       [code implementation](https://github.com/sodexx7/yui_erc1155/blob/0a924a78cf1f87f43b5645fa19f200fc31d16cd0/yul/ERC1155_YUI.yul#L474)   

3. ```event URI(string _value, uint256 indexed _id)```
     * After storing one token's URI, should emit this event
     * Get the token's URI slot, build the string data in memory from the storage, should depend on the URI's length(<=19bytes or >19 bytes) 
     ```M  
          startPos--------------->length_pos : the pos of the length's value 
          length_pos------------->length
          ength_pos+0x20---------> each value   ||
          ength_pos+0x20*2-------> each value   ||  Store the actual data
          ength_pos+0x20*3-------> each value   ||
          ength_pos+0x20*4-------> each value   ||
          ......


      ```
      * notice: *For the event's  string param, whose actual data in memory should store equal 0x20 times*

4. ```function updateURIWithTokenId(uint256 id,string memory URI) external;```
    * According to the tokenId, calculating the actual slot pos storing the tokens' URI
       


## Others
### Combine URI with tokenId
This is my previous implementation, but it's wrong according to the EIP1155, Actually just emit the input url string is fine.  But if one want to get this format URI from smart contract, the below logic can be resued.


* For example, if the basic URI was set as "https://aaaabcdn-domain/{id}.json"; then token Id is 1337. Then the emit URI wiil as    
  https://aaaabcdn-domain/0000000000000000000000000000000000000000000000000000000000000539.json
*  **How to combine the basic URI and the id to the new URI. the id format should as leading zero padded to 64 hex characters**
  1. This involved three parts, 1th part is the prefixURI which truncates the {id}.json; 2th part is get the id's hex string value; 3th part is should add the suffixURI(.json)
  2. Because the different mechniasm of storing the string depending on it's length(>19bytes,<19bytes). Extract the prefixURI should according to this spec, other parts keep the same preocession.
  3. Get the id's leading zero padded to 64 hex characters
    * see [How to get the id's leading zero padded to 64 hex characters](https://github.com/sodexx7/yui_erc1155/blob/main/URIOperation.md#L110) 
          


  * Build the new URI in the memory, whose procession is the same as dealing with array in memory

  ```M  
    startPos--------------->length_pos : the pos of the length's value 
    length_pos------------->length
    ength_pos+0x20---------> each value   ||
    ength_pos+0x20*2-------> each value   ||  Store the prefixValue+id's value+suffix's value
    ength_pos+0x20*3-------> each value   ||
    ength_pos+0x20*4-------> each value   ||
    ......


    --------------------------------------------------Demo URI--------------------------------------------------  
    Original URI  
    https://aaaabcdn-domain/{id}.json  

    New prefixURi
    https://aaaabcdn-domain/             length:24(0x18)  

    id(decimial) 314592                  length:64(0x40) 

    suffixURI .json                      length:5 (0x40) 
    
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\Required new URI\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    https://aaaabcdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json


    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\COMBINED NEW STRING IN MEMORY\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
    0x
    0000000000000000000000000000000000000000000000000000000000000020     -------> length-pos
    000000000000000000000000000000000000000000000000000000000000005d     -------> new URI's length  0x5d(51+64+5)
    68747470733a2f2f616161616263646e2d646f6d61696e2f3030303030303030    |||
    3030303030303030303030303030303030303030303030303030303030303030    |||    New String URI    
    3030303030303030303030303030303030303034636365302e6a736f6e          |||    https://aaaabcdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json

  ```

* reference: https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions

      

## How to get the id's leading zero padded to 64 hex characters?

* That is 64 hex characters. like 314592, whose format as this `000000000000000000000000000000000000000000000000000000000004cce0` 

* **Because that needs to store the hex format characters, not the hex value. so should get each hex's character's ASCII code to store**, then when returning the ASCII code, which will be convert to the hex's format string.
    
* My design, firstly, store the corrospeding ASCII code in the memory while getting the each postion's value of the id's hex value
Becasue each character needs to use 1 bytes, so each  ASCII code just occupy 1 bytes
    * Such as 314592, whose hex value is 0x4cce0. 0-->0x30  e--->65 c--->63 4--->34. So the memory should store as this *****3463636530
* Secondly, should padding the zero characters to the value, until the length achieved 64, Just as below shows

```M  
    id(decimial) 314592

    The ultimate String
    "000000000000000000000000000000000000000000000000000000000004cce0"

    The corrospending stored ASCII code(whose length = 64bytes)
    3030303030303030303030303030303030303030303030303030303030303030 
    
    303030303030303030303030303030303030303030303030303030 34 63   63 65  30
                                                        |   |  |   |  |   |
                                                        0    4  c  c   e  0

```
code implementation
* [hexOfNumToMem](https://github.com/sodexx7/yui_erc1155/blob/0a924a78cf1f87f43b5645fa19f200fc31d16cd0/yul/ERC1155_YUI.yul#L809) -->store the id's hex literal in the memory at the target pos 
* [fullHexOfZeroInMem](https://github.com/sodexx7/yui_erc1155/blob/0a924a78cf1f87f43b5645fa19f200fc31d16cd0/yul/ERC1155_YUI.yul#L794) -->padding the zero chars

*  other implemetaiton
[openzepplin-string ](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d155600d554d28b583a8ab36dee0849215d48a20/contracts/utils/Strings.sol#L65)
