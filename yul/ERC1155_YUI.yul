
//  YUI ERC20 yui udemy course familiar with BASIC DONE

// 1)define data structure  done

  //     data structure  todo CHECK
  //     mapping(uint256 id => mapping(address account => uint256)) private _balances;
  //     mapping(address account => mapping(address operator => bool)) private _operatorApprovals;

// 2)basic mint/ transfer   done 


// update _balances     done, not check
//         balances[id][from] = fromBalance - value;
//         _balances[id][to] += value;


// 1. Constructor
//     set the _setURI, my implementation, here 

// 2. when emit the event: event URI(string _value, uint256 indexed _id).
//     mint new id?



// 4. other functions

//     Autoher check
//     safeTransferFrom when from =0x00 . mint , to =0x00 burn
//     safeBatchTransferFrom

//     update the data structure


//     update. based on the array. 


// 5.reference
//   YUI how to deal with the string


// return string 
// This doesn't need to consider the memory? just return??
// doing https://www.udemy.com/course/advanced-solidity-yul-and-assembly/learn/lecture/34013526#questions

object "ERC1155_YUI" {
  code {
    // deploy the contract
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }

  object "Runtime" {

    code {
        // Dispatcher  

        // TODO toAdd mint, BathchMint, should only the owner has the right calling it?
        // mint, batchMint for test cases ???
        switch selector() 
        case 0x731133e9 /* mint(address,uint256,uint256,bytes)*/ {

          mint(decodeAsAddress(0),1,2,3)
          returnTrue()
        }
        case 0xb48ab8b6 /* batchMint(address,uint256[],uint256[],bytes)*/ {
          // array in memory no value? should mannuly operate, 

          // should I mannly operate the array to the memory?
          // check when  call like this batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data)
            // memory no data?
          // consistant ?
       
          batchMint(decodeAsAddress(0),1,2,3)
          returnTrue()
        }
        case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)"  */ {
          safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1),2,3,4)
          returnTrue()
        }
        case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
          returnUint(balanceOf(decodeAsAddress(0),decodeAsUint(1)))
        }
        case 0x2eb2c2d6 /* safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)  */ {
          safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1),2,3,4)
          returnTrue()
        }
        case 0xa22cb465 /* setApprovalForAll(address,bool)*/ { // bool false:0, true:1 ???
          setApprovalForAll(decodeAsAddress(0),decodeAsUint(1))
          returnTrue()
        }
        case 0xe985e9c5 /*isApprovedForAll(address,address)*/ { // bool false:0, true:1 ???
          returnUint(isApprovedForAll(decodeAsAddress(0),decodeAsAddress(1)))
        }
        // no functions match, just revert
        default {
            revert(0, 0)
        }

        function mint(to,idOffSet,valueOffSet,bytesOffset) {
          updateBalance(0,to,idOffSet,valueOffSet,"SINGAL")
          // smart contract check 
          if gt(extcodesize(to),0) {
            callOnERC1155Received(caller(),0,to,idOffSet,valueOffSet,bytesOffset)
            // TODO
            // check the return value
          }
          
        }
        
        function batchMint(to,idsOffSet,valuesOffSet,bytesOffset) {
          safeBatchTransferFrom(0,to,idsOffSet,valuesOffSet,bytesOffset)
        }

        function safeTransferFrom(from,to,idOffSet,valueOffSet,bytesOffset) {
          updateBalance(from,to,idOffSet,valueOffSet,"SINGAL")
          if gt(extcodesize(to),0) {
            callOnERC1155Received(caller(),from,to,idOffSet,valueOffSet,bytesOffset)
          }
        }

        function safeBatchTransferFrom(from,to,idsOffSet,valuesOffSet,bytesOffset) {
          updateBalance(from,to,idsOffSet,valuesOffSet,"BATCH")
          if gt(extcodesize(to),0) {
            callOnERC1155BatchReceived(caller(),from,to,idsOffSet,valuesOffSet,bytesOffset)

          }
        }

        function callOnERC1155Received(operator,from,to,idOffSet,valueOffSet,bytesOffset){
          let mem_size := buildCalldataInMem(operator,from,idOffSet,valueOffSet,bytesOffset,"SINGAL")
          
          let result := call(gas(), to, 0, 0, mem_size, 0, 0)
          returndatacopy(0, 0, returndatasize())
          return(0,0x20)
        }


        function callOnERC1155BatchReceived(operator,from,to,idsOffSet,valuesOffSet,bytesOffset){
          let mem_size := buildCalldataInMem(operator,from,idsOffSet,valuesOffSet,bytesOffset,"BATCH")
          
          let result := call(gas(), to, 0, 0, mem_size, 0, 0)
          returndatacopy(0, 0, returndatasize())
          return(0,0x20)
            
        }


       function setApprovalForAll(operator,isApproved) {
          // caller???  TODO check the caller is the owner??
          let offset := operatorApprovalStorageOffset(caller(),operator)
          sstore(offset, safeAdd(sload(offset), isApproved))

       }

       function updateBalance(from,to,idsOffSet,valuesOffset,isBatch) {
        switch isBatch
        case "BATCH" {
          // TODO just as uint and address, should check the type???
          let ids_length_pos := calldataload(add(4, mul(idsOffSet, 0x20)))
          let ids_length := calldataload(add(4,ids_length_pos))
      
          let values_length_pos := calldataload(add(4, mul(valuesOffset, 0x20)))
          let values_length := calldataload(add(4,values_length_pos))

          // TODO when ids length !== values length ,should get the min length
          // add(idsPos,0x20),mul(i,0x20)
          let i := 0
          for {} lt(i,ids_length) {i := add(i, 1)} {

              // 0x24 should add the 0x04(function singature)
              let id := calldataload(add(add(ids_length_pos,0x24),mul(i,0x20)))
              let value := calldataload(add(add(values_length_pos,0x24),mul(i,0x20)))

              if iszero(iszero(from)) {
                // one decrease value, one increase value
                // TODO check sufficient value/ overflow check
                deductFromBalanceWithId(from,id,value)
              }

              if iszero(iszero(to)) {
                // todo check overflow check
                addToBalanceWithId(to,id,value)
              }
              // todo emit event
            }
            }  
        case "SINGAL" { 
          let id :=    decodeAsUint(idsOffSet)
          let value := decodeAsUint(valuesOffset)
          // iszero(!0) =>0 =>iszero(0)=1 
          if iszero(iszero(from)) {
            // one decrease value, one increase value
            // TODO check sufficient value/ overflow check
            deductFromBalanceWithId(from,id,value)
          }

          if iszero(iszero(to)) {
            // todo check overflow check
            addToBalanceWithId(to,id,value)
          }
        }
      }

      ///////////////////////////////////////////////////////////////////////////Memory Operation/////////////////////////////////////////////////////////////////////////
      /**
        Copy the corrospending params to the memory, which should obey the EVM function calldata. The data in memroy will be as the CallData when calling the to address.
        
        Memory layout:
        0x00->0x04        function Signature
        0x04->0x24        opertor(caller())
        0x24->0x44        from address
        0x44->0xa0        ids pos(0x84+0x20)                                          ||| just store id if id is uint                         
        0x64->value_pos   value pos(should based on the actual size of the ids )      ||| just store value if value is uint
        0x84->bytes_pos   bytes pos(should based on the actual size of ids, values )  
        
        0xa0->            ids'size           
        ....              ids'each value

        value_pos->       value's size  
        ...               values'each value

        bytes_pos->       bytes's size
        ...               values'each value


        Params:
        operator:     who trigger the tx
        from:         from address
        idsOffSet:    The idsoffset of the calldata 
        valuesOffset: The valuesOffset of the calldata 
        bytesOffset:  The bytesOffset of the calldata 
        isBatch:      "BATCH"/"SINGAL" 
      */

      function buildCalldataInMem(operator,from,idsOffSet,valuesOffset,bytesOffset,isBatch) -> mem_size{

        switch isBatch
        case "BATCH" {

          datacopy(0, dataoffset("onERC1155BatchReceived"), datasize("onERC1155BatchReceived"))
          let functionSignature := keccak256(0, datasize("onERC1155BatchReceived"))
          mstore(0,functionSignature) 
          mstore(0x44,0xa0)  // ids pos in memory 

          let ids_length_pos,ids_size := CopyArrayToMemory(0xa4,idsOffSet) 
          mstore(0x64,add(0xa0,ids_size)) // values pos in memory

          let values_length_pos,values_size := CopyArrayToMemory(add(0xa4,ids_size),valuesOffset) 
          mstore(0x84,add(0xa0,add(ids_size,values_size))) // bytes pos in memory
        
          let bytes_size := copyBytesToMemory(add(0xa4,add(ids_size,values_size)),bytesOffset) // copy bytes to the memory
          mem_size := add(0xa4,add(ids_size,add(values_size,bytes_size)))
        
        }  
        case "SINGAL" { 
          datacopy(0, dataoffset("onERC1155Received"), datasize("onERC1155Received"))
          let functionSignature := keccak256(0, datasize("onERC1155Received"))
          mstore(0,functionSignature)
          
          mstore(0x44,decodeAsUint(idsOffSet))
          mstore(0x64,decodeAsUint(valuesOffset))
          mstore(0x84,0xa0) // bytes pos in memory
          let add_size := copyBytesToMemory(0xa4,bytesOffset)
          mem_size := add(0xa4,add_size)
          
        }
        
        // same parameter
        mstore(4,operator)
        mstore(0x24,from)

      }

      /**
        Copy the array in calldata to the memory at the mem_pos,including the array's length and each value. 

        Params:
        mem_pos: Memory postion, which as the beginning postion store the array's data
        offset:  The array's offset in calldata
        
        data_length_pos: the data's length pos in calldata
        data_length:     the array's length(add 0x20<length>) 

        More details: https://github.com/sodexx7/yui_erc1155/blob/main/MemoryExplain.md#L70

      */
      function CopyArrayToMemory(mem_pos,offset) -> data_length_pos,data_length {
        data_length_pos := calldataload(add(4, mul(offset, 0x20)))
        data_length := calldataload(add(4,data_length_pos))

        data_length := add(0x20,mul(data_length,0x20))
        calldatacopy(mem_pos,add(4,data_length_pos),data_length)
        
      }
      
      // iszero iszero CHECK
      /**
        Copy the bytes in calldata to the memory at the mem_pos,including the bytes's length and its value. 

        Params:
        bytes_size_0x20: 0x40(bytes'length <=0x20) 
                        Calculated on the formual when  bytes'length > 0x20  
                        e.g. bytes'length = 0x40, bytes_size_0x20 = 0x60
                             bytes'length = 0x41, bytes_size_0x20 = 0x80
                   
        More details: https://github.com/sodexx7/yui_erc1155/blob/main/MemoryExplain.md#L73
      */
      function copyBytesToMemory(mem_pos,bytesOffset) -> bytes_size_0x20 {
        let bytes_pos := add(4, mul(bytesOffset, 0x20)) // 0x64??? calldata_pos
        let bytes_length_pos := calldataload(bytes_pos) // 0x80  length_pos
        let bytes_length := calldataload(add(bytes_length_pos,0x04)) 
       

        // Calculate the size of the bytes, which based on the 0x20
        // iszero iszero       ||   not   bytes_length > 0x20  <=> bytes_length <= 0x20
        
        switch iszero(iszero(gt(bytes_length,0x20)))
          case 1 {
                  bytes_size_0x20 := add(bytes_size_0x20,0x20) // including length
                  
                  // return(mem_pos,0x40)
                
                }  // <=0x20
          case 0 {  // > 0x20 // This shoud CHeck TODO 
                  bytes_size_0x20 := div(bytes_length,0x20)

                  if gt(mod(bytes_length,0x20),0) { bytes_size_0x20 := add(bytes_size_0x20,1) }

                  bytes_size_0x20 :=add(mul(bytes_size_0x20,0x20),0x20)

                 }          

        calldatacopy(mem_pos,add(bytes_length_pos,0x04),bytes_size_0x20)

      }

      ///////////////////////////////////////////////////////////////////////////storage layout/////////////////////////////////////////////////////////////////////////
        // should the check the implementation maybe has some conflict?
        function balancesSlot() -> p { p := 0 }
        // todo the below is not used CHECK
        function operatorApprovalsSlot() -> p { p := 1 }

        // This implementation is samke like solidity how to manipulate the nested mapping keccak256(account,keccak256(id,slot)) 
        function balanceWithIdStorageOffset(id, account) -> offset {
           
           mstore(0, id)
           mstore(0x20, balancesSlot())
           
           mstore(0x20,keccak256(0, 0x40)) 
           mstore(0, account)
           offset := keccak256(0, 0x40)
        }

        function operatorApprovalStorageOffset(account, operator) -> offset {
            mstore(0, account)
            mstore(0x20, operator)
            offset := keccak256(0, 0x40)
        }

        /***
          todo
          1) batch test
          2) all situations check
          3) add event
        ***/
       

        function addToBalanceWithId(account,id,amount) {
          let offset := balanceWithIdStorageOffset(id,account)
          sstore(offset, safeAdd(sload(offset), amount))
        }

        function deductFromBalanceWithId(account,id, amount) {
          let offset := balanceWithIdStorageOffset(id,account)
          let bal := sload(offset)
          // require bal check
          sstore(offset, sub(bal, amount))
        }


      ///////////////////////////////////////////////////////////////////////////storage access/////////////////////////////////////////////////////////////////////////

      function balanceOf(account,id) -> bal {
          bal := sload(balanceWithIdStorageOffset(id,account))
      }

      function isApprovedForAll(owner,operator) -> isApproved {
        isApproved := sload(operatorApprovalStorageOffset(owner,operator))
      }

       /* ---------- utility functions ---------- */
      
      function safeAdd(a, b) -> r {
        r := add(a, b)
        if or(lt(r, a), lt(r, b)) { revert(0, 0) }
        
      }

      ///////////////////////////////////////////////////////////////////////////calldata encoding functions///////////////////////////////////////////////////////////////
      //  form calldata => memory/stack =>return
      function returnUint(v) {
        mstore(0, v)
        return(0, 0x20)
      }

      function returnTrue() {
          returnUint(1)
      }

      function selector() -> s {
        s := shr(mul(28,8),calldataload(0))
      }

      // address format: 0x + "0"*20+"f"*12
      function decodeAsAddress(offset) -> v {
        v := decodeAsUint(offset)
        if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
            revert(0, 0)
        }
      }

      function decodeAsUint(offset) -> v {
        let pos := add(4, mul(offset, 0x20))
        if lt(calldatasize(), add(pos, 0x20)) {
            revert(0, 0)
        }
        v := calldataload(pos)
      }

      

      // todo, especially for the array  
      /***
      function balanceOf(accounts,ids) -> bal {
          bal := sload(balanceWithIdStorageOffset(id,account))
      }
      **/

    }

    // data "Message" "test string test stringtest stringtest stringtest string test string test stringtest stringtest stringtest string"
    // where data should sites?
    data "onERC1155Received" "onERC1155Received(address,address,uint256,uint256,bytes)"
    data "onERC1155BatchReceived" "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
  
  }

}
    
// to check, store _balances use which implementation? 
// my current implementation(_balances) is the slot value  keccak256(id,account)   
// _operatorApprovals keccak256(account,operator)
// there are some weekness? can conflicyt.

// supportsInterface ??
// todo, YUI code format

/**
reference:
 // operate memory array.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Arrays.sol
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol
        // https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol
*/