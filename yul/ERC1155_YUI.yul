
//  YUI ERC20 yui udemy course familiar with BASIC DONE

// 1. Constructor
//     set the _setURI, my implementation, here 

// 2. when emit the event: event URI(string _value, uint256 indexed _id).
//     mint new id?


// 5.reference
//   YUI how to deal with the string


// return string 
// This doesn't need to consider the memory? just return??
// doing https://www.udemy.com/course/advanced-solidity-yul-and-assembly/learn/lecture/34013526#questions

object "ERC1155_YUI" {
  code {
      
    // Store the creator in slot zero.
    sstore(0, caller())


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
        case 0xf5298aca /* "burn(address,uint256,uint256)" */ {
          burn(decodeAsAddress(0),1,2)
          returnTrue()
        }
        case 0xf6eb127a /* "batchBurn(address,uint256[],uint256[])" */ {
          batchBurn(decodeAsAddress(0),1,2)
          returnTrue()
        }
        case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)"  */ {
          safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1),2,3,4)
          returnTrue()
        }
        case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
          returnUint(balanceOf(decodeAsAddress(0),decodeAsUint(1)))
        }
        case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
          // TODO check type 
          balanceOfBatch(0,1) 
        }
        case 0x2eb2c2d6 /* safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)  */ {
          safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1),2,3,4)
          returnTrue()
        }
        case 0xa22cb465 /* setApprovalForAll(address,bool)*/ { // bool false:0, true:1 ???
          setApprovalForAll(decodeAsAddress(0),decodeAsUint(1))
          returnTrue()
        }
        case 0xe985e9c5 /*isApprovedForAll(address,address)*/ { // bool false:0, true:1 
          returnUint(isApprovedForAll(decodeAsAddress(0),decodeAsAddress(1)))
        }
        case 0x02fe5305 /*setURI(string)*/ { // CHECK when construct or the onwer call?
          setURI(0)
          returnTrue()
        }
        case 0x7754305c /*getURI()*/ { 
          getURI()
          returnTrue()
        }
        // no functions match, just revert
        default {
            revert(0, 0)
        }

        function mint(to,idOffSet,valueOffSet,bytesOffset) {
          safeTransferFrom(0,to,idOffSet,valueOffSet,bytesOffset)
        }
        
        function batchMint(to,idsOffSet,valuesOffSet,bytesOffset) {
          safeBatchTransferFrom(0,to,idsOffSet,valuesOffSet,bytesOffset)
        }

        function burn(from,idOffSet,valueOffSet) {
          // TODO, should check the rights
          updateBalance(from,0,idOffSet,valueOffSet,"SINGAL")
        }
        
        function batchBurn(from,idsOffSet,valuesOffSet) {
          // TODO, should check the rights
          updateBalance(from,0,idsOffSet,valuesOffSet,"BATCH")
        }

        function safeTransferFrom(from,to,idOffSet,valueOffSet,bytesOffset) {
          revertIfZeroAddress(to) // TODO show customer_error
          updateBalance(from,to,idOffSet,valueOffSet,"SINGAL")
          // to is the calller itself, skip
          if iszero(eq(caller(),to)) {
            if gt(extcodesize(to),0) {
              callOnERC1155Received(caller(),from,to,idOffSet,valueOffSet,bytesOffset)
            }
          }
        }

        function safeBatchTransferFrom(from,to,idsOffSet,valuesOffSet,bytesOffset) {
          revertIfZeroAddress(to) // TODO show customer_error
          updateBalance(from,to,idsOffSet,valuesOffSet,"BATCH")
          // to is the calller itself, skip
          if iszero(eq(caller(),to)) {
            if gt(extcodesize(to),0) {
              callOnERC1155BatchReceived(caller(),from,to,idsOffSet,valuesOffSet,bytesOffset)
            }
          }
        }

        // TODO, THE below funtion can extract the reuse code, that related the updataBalacnes
        function balanceOfBatch(addressesOffset,idsOffset) {
          // TODO just as uint and address, should check the type???
          let addresses_length_pos := calldataload(add(4, mul(addressesOffset, 0x20)))
          let addresses_length := calldataload(add(4,addresses_length_pos))
      
          let ids_length_pos := calldataload(add(4, mul(idsOffset, 0x20)))
          let ids_length := calldataload(add(4,ids_length_pos))

          // TODO , there should add message
          revertIfArrayLenNoEqual(addresses_length,ids_length)
        
          let i := 0
          for {} lt(i,addresses_length) {i := add(i, 1)} {
              // 0x24 should add the 0x04(function singature)
              let addr := calldataload(add(add(addresses_length_pos,0x24),mul(i,0x20)))
              let id := calldataload(add(add(ids_length_pos,0x24),mul(i,0x20)))
              mstore(add(0x40,mul(i,0x20)),balanceOf(addr,id))
          }

          // after store the below value, skip the confict that the used memory by  balanceWithIdStorageOffset
          mstore(0,0x20)
          mstore(0x20,addresses_length)
          return(0,add(0x40,mul(addresses_length,0x20)))
        }

        function callOnERC1155Received(operator,from,to,idOffSet,valueOffSet,bytesOffset){
          let mem_size := buildCalldataInMem(operator,from,idOffSet,valueOffSet,bytesOffset,"SINGAL")
          
          let result := call(gas(), to, 0, 0, mem_size, 0, 0)
          returndatacopy(0, 0, returndatasize())

          switch result
          case 0 { //No-implementation OnERC1155Received
              revert(0, returndatasize())
          }
          default {
            if eq(mload(0) ,hex"f23a6e61") { // //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"
              return(0, returndatasize())
            }
            revert(0, returndatasize()) // return bytes != 0xf23a6e61
          // check return value
          // 1: return true, if bytes ==  ERC1155TokenReceiver.onERC1155BatchReceived.selector 
          // 2: revert No-implement ERC1155TokenReceiver
          // 3: revert false bytes
          }
        }


        function callOnERC1155BatchReceived(operator,from,to,idsOffSet,valuesOffSet,bytesOffset){
          let mem_size := buildCalldataInMem(operator,from,idsOffSet,valuesOffSet,bytesOffset,"BATCH")
          
          let result := call(gas(), to, 0, 0, mem_size, 0, 0)
          returndatacopy(0, 0, returndatasize())

          switch result
          case 0 { //No-implementation OnERC1155BatchReceived
              revert(0, returndatasize())
          }
          default {
            if eq(mload(0) ,hex"bc197c81") { // //bytes4(keccak256("ERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
               return(0, returndatasize())
            }
            revert(0, returndatasize()) // return bytes != 0xbc197c81
            // check return value
            // 1: return true, if bytes ==  ERC1155TokenReceiver.onERC1155BatchReceived.selector 
            // 2: revert No-implement ERC1155TokenReceiver
            // 3: revert false bytes
          }
        }

       function setApprovalForAll(operator,isApproved) {
          // caller???  TODO check the caller is the owner??
          let offset := operatorApprovalStorageOffset(caller(),operator)
          sstore(offset, safeAdd(sload(offset), isApproved))
          emitApprovalForAll(caller(),operator,isApproved)

       }

       function updateBalance(from,to,idsOffSet,valuesOffset,isBatch) {
        switch isBatch
        case "BATCH" {
          // TODO just as uint and address, should check the type???
          let ids_length_pos := calldataload(add(4, mul(idsOffSet, 0x20)))
          let ids_length := calldataload(add(4,ids_length_pos))
      
          let values_length_pos := calldataload(add(4, mul(valuesOffset, 0x20)))
          let values_length := calldataload(add(4,values_length_pos))

          revertIfArrayLenNoEqual(ids_length,values_length)
          // require(ids_length) // ids_length should gt 0 TODO add custom error


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
          }
           emitTransferBatch(caller(),from,to,idsOffSet,valuesOffset)
           emitURI(URISlot(),decodeAsUint(idsOffSet))
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
          // Emit TransferSingle, should notice are there conflict with using memory
          emitTransferSingle(caller(),from,to,id,value)
         
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
          let functionSignature := keccak256(0, datasize("onERC1155BatchReceived")) // 0xbc197c81
          mstore(0,functionSignature) 
          mstore(0x44,0xa0)  // ids pos in memory 

          let ids_length_pos,ids_size := copyArrayToMemory(0xa4,idsOffSet) 
          mstore(0x64,add(0xa0,ids_size)) // values pos in memory

          let values_length_pos,values_size := copyArrayToMemory(add(0xa4,ids_size),valuesOffset) 
          mstore(0x84,add(0xa0,add(ids_size,values_size))) // bytes pos in memory
        
          let bytes_size := copyBytesToMemory(add(0xa4,add(ids_size,values_size)),bytesOffset) // copy bytes to the memory
          mem_size := add(0xa4,add(ids_size,add(values_size,bytes_size)))
        
        }  
        case "SINGAL" { 
          datacopy(0, dataoffset("onERC1155Received"), datasize("onERC1155Received"))
          let functionSignature := keccak256(0, datasize("onERC1155Received")) // 0xf23a6e61
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
      function copyArrayToMemory(mem_pos,offset) -> data_length_pos,data_length {
        data_length_pos := calldataload(add(4, mul(offset, 0x20)))
        data_length := calldataload(add(4,data_length_pos))

        data_length := add(0x20,mul(data_length,0x20))
        calldatacopy(mem_pos,add(4,data_length_pos),data_length)
        
      }
      
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
        switch gte(bytes_length,0x20)
          case 1{ // >=0x20 
                  bytes_size_0x20 := div(bytes_length,0x20)
                  if gt(mod(bytes_length,0x20),0) { bytes_size_0x20 := add(bytes_size_0x20,1) }
                  bytes_size_0x20 :=add(mul(bytes_size_0x20,0x20),0x20)
                  calldatacopy(mem_pos,add(bytes_length_pos,0x04),bytes_size_0x20)
          }
          case 0{ // < 0x20
                switch iszero(bytes_length)
                  case 1 { // specifical situation: when bytes= 0x, no length store,just store 0x00
                    mstore(mem_pos,0)
                    bytes_size_0x20 := 0x20
                  }
                  case 0 { // len =0
                    bytes_size_0x20 := 0x40 // including length
                    calldatacopy(mem_pos,add(bytes_length_pos,0x04),bytes_size_0x20)
                  } 
          } 
      }
      ///////////////////////////////////////////////////////////////////////////storage layout/////////////////////////////////////////////////////////////////////////
        // should the check the implementation maybe has some conflict?
        function balancesSlot() -> p { p := 0 }
        // todo the below is not used CHECK
        function operatorApprovalsSlot() -> p { p := 1 }

        function URISlot() -> p { p := 2 }

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
          // TODO  add customer error check balance is enough
          let offset := balanceWithIdStorageOffset(id,account)
          let addrBalance := sload(offset)
          require(lte(amount,addrBalance))
          // require bal check
          sstore(offset, sub(addrBalance, amount))
        }

        // reference: https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#bytes-and-string length means bytes
        function setURI(URIOffset){
           // URISlot()
           let URI_pos := add(4, mul(0x20, URIOffset)) 
           let URI_length_pos := calldataload(URI_pos)
           let URI_length := calldataload(add(4,URI_length_pos)) 

          //  DOING check the edge length
           switch lt(URI_length,0x20) 
            // TODO check the length
            case 1 { // URI_length < 0x20 
                // compat the data
                // actual data + URI_length in one slot 
                let actualData := calldataload(add(URI_length_pos,0x24))
                // the lowest-order byte stores(31th bytes) the length 
                sstore(URISlot(),or(actualData,mul(URI_length,2))) // get the new compat data V or  00 = V 
            }
            case 0 { // URI_length >= 0x20
                // URISlot()  key-value: length * 2 + 1
                // store keccak result
                sstore(URISlot(),add(mul(URI_length,2),1)) // according to evm how to store string, when length>31bytes
                // calculate the postion
                mstore(0,URISlot())
                let firstPos := keccak256(0, 0x20) 
                // calculate how many slots needed? last round should right most
                let rounds := div(URI_length,0x20)
                let i := 0
                
                for {} lt(i,rounds) {i := add(i, 1)} {
                  
                  let eachData := calldataload(add(add(URI_length_pos,0x24),mul(i,0x20)))

                  sstore(add(firstPos,mul(i,1)),eachData)
                }
                
                let modSize := mod(URI_length,0x20)
                if gt(modSize,0) {
                  let lastData := calldataload(add(add(URI_length_pos,0x24),mul(rounds,0x20)))
                  sstore(add(firstPos,rounds),lastData)
                }
            }
        }

        function getURI(){
          let urlData := sload(URISlot())
          // get the last bytes value.  judge by the low the doc indtroduce or by the length
          // current by the length value

          // get the length
          let length := and(urlData,0x00000000000000000000000000000000000000000000000000000000000000ff)

          // VV or 0 == VV
          // VV or 1 
          
          // This point should write to the md.file
          // 31bytes * 2 = 0x3e 
          // when the length<=21 bytes, as length <= 31bytes * 2 = 0x3e
          switch lte(length,0x3e)
            case 1 {
              mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)
              mstore(0x20,div(length,2)) // extract url from slot, the length should div 2.
              // mstore(0x40,and(urlData,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00)) // get the actual data
              // return(0,0x60)

              // TEST get the url except the {id}.json  https://abcdn-domain/ {id}.json
              //  length  7bytes   {id}.json 8bytes  /// {id}.json 9bytes

              // len:30bytes, suffix:9bytes. 21bytes
              mstore(0x20,0x15) 
              // let testData := shr(mul(11,8),urlData)
              mstore(0x40,urlData)
              return(0,0x60)

              // Actual len:  sub tail 9 bytes.


            }
            case 0 { // length > 31bytes * 2

              mstore(0,URISlot())
              let firstPos := keccak256(0, 0x20) 

              mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)
              let actualLen := div(sub(length,1),2)
              mstore(0x20,actualLen)
              
              let rounds := div(actualLen,0x20)
              let i := 0 
              for {} lt(i,rounds) {i := add(i, 1)} {
                mstore(add(0x40,mul(i,0x20)),sload(add(firstPos,i)))  
              }
              let memSize := add(0x40,mul(0x20,rounds))

              let modSize := mod(actualLen,0x20)
              if gt(modSize,0) {
                mstore(mul(i,0x20),sload(add(firstPos,rounds)))
                memSize := add(memSize,0x20)
              }
              return(0,memSize)
            }

      }

      ///////////////////////////////////////////////////////////////////////////storage access/////////////////////////////////////////////////////////////////////////

      function balanceOf(account,id) -> bal {
          bal := sload(balanceWithIdStorageOffset(id,account))
      }

      function isApprovedForAll(owner,operator) -> isApproved {
        isApproved := sload(operatorApprovalStorageOffset(owner,operator))
      }

       /* ---------- utility functions ---------- */
      function lte(a, b) -> r {
        r := iszero(gt(a, b))
      }
      
      function gte(a, b) -> r {
          r := iszero(lt(a, b))
      } 
      
      function safeAdd(a, b) -> r {
        r := add(a, b)
        if or(lt(r, a), lt(r, b)) { revert(0, 0) }
        
      }

      function revertIfZeroAddress(addr) {
        require(addr)
      }

      // todo add custom_error
      function require(condition) {
          if iszero(condition) { revert(0, 0) }
      }

      // TODO add custom_error
      function revertIfArrayLenNoEqual(idsSize,amountsSize){
          if iszero(eq(idsSize,amountsSize)) { revert(0, 0) }
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

      // DOING indexed 3/2/1
      ///////////////////////////////////////////////////////////////////////////events///////////////////////////////////////////////////////////////

      // TODO, where emit the event
      // TransferSingle(address,address,address,uint256,uint256) 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
      function emitTransferSingle(operator,from,to,id,value) {
        let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        mstore(0,id)
        mstore(0x20,value)
        log4(0,0x40, signatureHash,operator,from,to)
      }

      /**
      Memory layout:
      0x00->0x20      : ids pos
      0x20->value_pos : value pos
      0x40->0x60      : ids len
      
      ....


      value_pos       : value len 
      
      */
      // TransferBatch(address,address,address,uint256[],uint256[]) 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
      function emitTransferBatch(operator,from,to,idsOffSet,valuesOffset) {
        let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
        
        mstore(0,0x40) // ids pos in memory
        let ids_length_pos,ids_size :=  copyArrayToMemory(0x40,idsOffSet)
        mstore(0x20,add(0x40,ids_size)) // values pos in memory
        
        let values_length_pos,values_size := copyArrayToMemory(add(0x40,ids_size),valuesOffset) 
        let mem_size := add(0x40,add(ids_size,values_size))

        log4(0, mem_size, signatureHash,operator,from,to)
      }
      // ApprovalForAll(address,address,bool)   0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
      function emitApprovalForAll(owner,operator,isApproved) {
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
        mstore(0,isApproved)
        log3(0, 0x20, signatureHash,owner,operator)
      }

      //  https://eips.ethereum.org/EIPS/eip-1155#metadata

      // URI(string,uint256) 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b

      // reference: https://docs.soliditylang.org/en/latest/yul.html#literals  literals shows

      //DOING refactor the funcitons
      function emitURI(URISlotVal,id) {
        //  dealing url in memory, sub tail 9 bytes
        let urlData := sload(URISlotVal)
        let length := and(urlData,0x00000000000000000000000000000000000000000000000000000000000000ff)

        switch lte(length,0x3e)
          case 1 {

            mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)

            let urlActualData :=  and(urlData,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00)
            
            let prefixURIlen := sub(div(length,2),SUFFIXURILEN())

            let prefixURIData := getDataByRange(urlActualData,0,prefixURIlen)

            let suffixURIData := getDataByRange(urlActualData,add(prefixURIlen,4),sub(SUFFIXURILEN(),4)) // suffix should truncate {id}, whose length = 4

            mstore(0x20,add(prefixURIlen,0x45)) //length of prefixURI+id(hex)+suffixURI

            // store prefixURIData,id(hex),suffixURIData in memory
            mstore(0x40,prefixURIData)

            let idStartPos := add(0x40,prefixURIlen)
            let idEndPos := add(idStartPos,0x40)
            let leftPos := hexOfNumToMem(id,sub(idEndPos,1)) // 
            // fill "o" between idStartPos and lastPos
            fullHexOfZeroInMem(leftPos,idStartPos)

            mstore(idEndPos,suffixURIData) 

            return(0,add(idEndPos,sub(SUFFIXURILEN(),4)))
          }
          case 0 { // length > 31bytes * 2

            mstore(0,URISlotVal)
            let firstPos := keccak256(0, 0x20) 

            mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)
            
            let prefixURIlen := sub(div(sub(length,1),2),SUFFIXURILEN())

            mstore(0x20,add(prefixURIlen,0x45)) //length of prefixURI+id(hex)+suffixURI

            // mstore from 0x40 until the prefixURI ends
            let rounds := div(prefixURIlen,0x20)
            let i := 0 
            for {} lt(i,rounds) {i := add(i, 1)} {
              mstore(add(0x40,mul(i,0x20)),sload(add(firstPos,i)))  
            }

            let modSize := mod(prefixURIlen,0x20)
            if gt(modSize,0) {
              mstore(add(0x40,mul(i,0x20)),sload(add(firstPos,rounds)))
            }

            let idStartPos := add(0x40,prefixURIlen)
            let idEndPos := add(idStartPos,0x40)
            
            // mstore id(hex),suffixURIData in memory
            let leftPos := hexOfNumToMem(id,sub(idEndPos,1)) // 
            // fill "o" between idStartPos and lastPos
            fullHexOfZeroInMem(leftPos,idStartPos)

            //  get the last 5 bytes.
            mstore(idEndPos,".json") 
            
            
            return(0,add(idEndPos,sub(SUFFIXURILEN(),4)))
            
          }
      }
  
    ///////////////////////////////////////////////////////////////////////////URI operation///////////////////////////////////////////////////////////////
    
    // The common URI suffix is .json
    // The common URI suffix with id is {id}.json
    // 
    function SUFFIXURILEN() -> r {
      r := 9 // {id}.json 9 bytes
    }
   
    // the num between (0,9) or [a,f]
    // the blew code should optimize
    function getActualHex(num) ->r {

      let startHex := 0x30 // 0x30 --->0x39  0->9
      let startHex2 := 0x61 // 0x61 --->0x66  a->f 10-15

      if lte(num,9) { r := add(startHex,num) }

      if gt(num,9) { r := add(startHex2,sub(num,10)) }

    }

    // pos 0x59  
    //  000000000000000000000000000000000000000000000000000000000004cce0

    // 64 char
    // 1 char 2hex
    // HexOfZero
    function fullHexOfZeroInMem(startPos,endPos) {
      
      for {} gte(startPos,endPos) {startPos := sub(startPos,1)} {
            mstore8(startPos,getActualHex(0))
      }
    }

    // Using the recrusive method, has some bad effects?
    // Using for TODO ???
    // pos test??? pos start 0x40

    // curretnly directly store the the realted asii, one ascii represent 8 bytes

    // reference : https://www.asciitable.com/
    // two different implementaitons TODO compare
    // DOING ALL 000000000(64) + string

    // Store num's bytes literal in memory at the pos,
    // hexOfNumToMem
    function hexOfNumToMem(id,pos)->actualPos{

      let divRes := div(id,16)
      let modRes := mod(id,16)
      mstore8(pos,getActualHex(modRes))
      pos := sub(pos,1)
      actualPos := pos

      if lt(divRes,16){
      if gt(divRes,0) {
        mstore8(pos,getActualHex(divRes))
        pos := sub(pos,1)
      }
      actualPos := pos
      }
      
      if gte(divRes,16) {actualPos := hexOfNumToMem(divRes,pos)}
    
    }

  
  function calculateSize(id) ->size {

    size := 0
    for{} gt(id,16) {id := div(id,16)} {
        size := add(size,1)
    }

    if gt(id,0) { size := add(size,1)}
  }

  // 0x7b69647d2e6a736f6e0000000000000000000000000000000000000000000000
  // 0x1111111111111111110000000000000000000000000000000000000000000000
  //  TODO more explain show the logic
  function getDataByRange(value,startPos,len)->res {

    if gt(startPos,0) {
        value := shl(mul(startPos,8),value)
    }

    // first step, left shift the value. make the startPos as the 0x0
    let markValue := sub(exp(0x100,len),1)
    let leftMostMakrValue := shl(mul(8,sub(0x20,len)),markValue)
    res := and(value,leftMostMakrValue)

} 
    

  // convert num to hex 
  function asciiConvert(original) -> r {

      let startVal := 0x30
      let result := sub(original,startVal)
      switch lte(result,9)
          case 1 {
              r := add(startVal,result)
          }
          case 0 {
            let secVal := 0x61
            result := sub(original,secVal)
            if lte(result,6){
              r := add(secVal,result)
            }
        }
  }

  

    // TransferSingle(address,address,address,uint256,uint256);

    // TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    // TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    // ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    // URI(string _value, uint256 indexed _id);


      

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

    data "URI_LESS_32BYTES" "https://cdn-domain/{id}.json"
    data "URI_GREATER_32BYTES" "https://token-cdn-domain/{id}.json"

  
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