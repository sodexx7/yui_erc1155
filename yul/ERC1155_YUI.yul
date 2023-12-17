object "ERC1155_YUI" {
  code {

    // deploy the contract
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }

  object "Runtime" {

    code {
        // Dispatcher  
        switch selector() 
        case 0x731133e9 /* mint(address,uint256,uint256,bytes)*/ {

          mint(decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2),decodeAsStringOrBytes(3))
          returnTrue()
        }
        case 0xb48ab8b6 /* batchMint(address,uint256[],uint256[],bytes)*/ {
       
          batchMint(decodeAsAddress(0),decodeAsArray(1),decodeAsArray(2),decodeAsStringOrBytes(3))
          returnTrue()
        }
        case 0xf5298aca /* "burn(address,uint256,uint256)" */ {
          burn(decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2))
          returnTrue()
        }
        case 0xf6eb127a /* "batchBurn(address,uint256[],uint256[])" */ {
          batchBurn(decodeAsAddress(0),decodeAsArray(1),decodeAsArray(2))
          returnTrue()
        }
        case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)"  */ {
          safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1),decodeAsUint(2),decodeAsUint(3),decodeAsStringOrBytes(4))
          returnTrue()
        }
        case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
          returnUint(balanceOf(decodeAsAddress(0),decodeAsUint(1)))
        }
        case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {

          balanceOfBatch(decodeAsArray(0),decodeAsArray(1)) 
        }
        case 0x2eb2c2d6 /* safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)  */ {
          safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1),decodeAsArray(2),decodeAsArray(3),decodeAsStringOrBytes(4))
          returnTrue()
        }
        case 0xa22cb465 /* setApprovalForAll(address,bool)*/ { // bool false:0, true:1 

          setApprovalForAll(decodeAsAddress(0),decodeAsUint(1))
          returnTrue()
        }
        case 0xe985e9c5 /*isApprovedForAll(address,address)*/ { // bool false:0, true:1 

          returnUint(isApprovedForAll(decodeAsAddress(0),decodeAsAddress(1)))
        }
        case 0x02fe5305 /*setURI(string)*/ { 

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

        function mint(to,id,value,bytesPos) {
          safeTransferFrom(0,to,id,value,bytesPos)
        }
        
        function batchMint(to,idsPos,valuesPos,bytesPos) {
         
          safeBatchTransferFrom(0,to,idsPos,valuesPos,bytesPos)
        }

        function burn(from,id,value) {
          // TODO, should check the rights
          updateBalance(from,0,id,value,"SINGAL")
        }
        
        function batchBurn(from,idsPos,valuesPos) {
          // TODO, should check the rights
          updateBalance(from,0,idsPos,valuesPos,"BATCH")
        }

        function safeTransferFrom(from,to,id,value,bytesPos) {

          revertIfZeroAddress(to) // TODO show more customer_error
          updateBalance(from,to,id,value,"SINGAL")

          // to is the calller itself, skip
          if iszero(eq(caller(),to)) {
            if gt(extcodesize(to),0) {
              callOnERC1155Received(caller(),from,to,id,value,bytesPos)
            }
          }
        }

        function safeBatchTransferFrom(from,to,idsPos,valuesPos,bytesPos) {

          revertIfZeroAddress(to) // TODO show more customer_error
          updateBalance(from,to,idsPos,valuesPos,"BATCH")

          // to is the calller itself, skip
          if iszero(eq(caller(),to)) {
            if gt(extcodesize(to),0) {
              callOnERC1155BatchReceived(caller(),from,to,idsPos,valuesPos,bytesPos)
            }
          }
        }
        
        function balanceOfBatch(addresses_length_pos,ids_length_pos) {

          let addresses_length := calldataload(add(4,addresses_length_pos))
      
          // let ids_length_pos := calldataload(add(4, mul(idsPos, 0x20)))
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

          //why mstore 0x00->0x20 in the end?  after store the below value, skip the confict that the used memory by  balanceWithIdStorageOffset
          mstore(0,0x20)
          mstore(0x20,addresses_length)
          return(0,add(0x40,mul(addresses_length,0x20)))
        }

        function callOnERC1155Received(operator,from,to,id,value,bytesPos){
          let mem_size := buildCalldataInMem(operator,from,id,value,bytesPos,"SINGAL")
          
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

        function callOnERC1155BatchReceived(operator,from,to,idsPos,valuesPos,bytesPos){
          let mem_size := buildCalldataInMem(operator,from,idsPos,valuesPos,bytesPos,"BATCH")
          
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

        function updateBalance(from,to,ids_length_pos,values_length_pos,isBatch) {
        switch isBatch
        case "BATCH" {
          let ids_length := calldataload(add(4,ids_length_pos))
       
          // let values_length_pos := calldataload(add(4, mul(valuesPos, 0x20)))
          let values_length := calldataload(add(4,values_length_pos))

          revertIfArrayLenNoEqual(ids_length,values_length)
          // require(ids_length) // ids_length should gt 0 TODO add custom error this related the param type check

          // TODO when ids length !== values length ,should get the min length, the id's length == values length openzepplin no this requirement?
          // For THE EIP1155 no these requirements
          let i := 0
          for {} lt(i,ids_length) {i := add(i, 1)} {

              // 0x24 should add the 0x04(function singature)
              let id := calldataload(add(add(ids_length_pos,0x24),mul(i,0x20)))
              let value := calldataload(add(add(values_length_pos,0x24),mul(i,0x20)))

              // one decrease value, one increase value
              if iszero(iszero(from)) {
                
                deductFromBalanceWithId(from,id,value)
              }

              if iszero(iszero(to)) {

                // todo check overflow check
                addToBalanceWithId(to,id,value)
              }
          }
           emitTransferBatch(caller(),from,to,ids_length_pos,values_length_pos)
           
        }  
        case "SINGAL" { 
          // SINGAL just means the id or value
          let id :=    ids_length_pos
          let value := values_length_pos
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
          
          emitTransferSingle(caller(),from,to,id,value)
          emitURI(URISlot(),id)
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
          idsPos:    The idsPos of the calldata                                   ||| just id for SINGAL
          valuesPos: The valuesPos of the calldata                                ||| just value for SINGAL
          bytesPos:  The bytesPos of the calldata 
          isBatch:      "BATCH"/"SINGAL" 
        */

        function buildCalldataInMem(operator,from,idsPos,valuesPos,bytesPos,isBatch) -> mem_size{

          switch isBatch
          case "BATCH" {
            datacopy(0, dataoffset("onERC1155BatchReceived"), datasize("onERC1155BatchReceived"))
            let functionSignature := keccak256(0, datasize("onERC1155BatchReceived")) // 0xbc197c81
            mstore(0,functionSignature) 
            mstore(0x44,0xa0)  // ids pos in memory 

            let ids_length_pos,ids_size := copyArrayToMemory(0xa4,idsPos) 
            mstore(0x64,add(0xa0,ids_size)) // values pos in memory

            let values_length_pos,values_size := copyArrayToMemory(add(0xa4,ids_size),valuesPos) 
            mstore(0x84,add(0xa0,add(ids_size,values_size))) // bytes pos in memory
          
            let bytes_size := copyBytesToMemory(add(0xa4,add(ids_size,values_size)),bytesPos) // copy bytes to the memory
            mem_size := add(0xa4,add(ids_size,add(values_size,bytes_size)))
          
          }  
          case "SINGAL" { 
            datacopy(0, dataoffset("onERC1155Received"), datasize("onERC1155Received"))
            let functionSignature := keccak256(0, datasize("onERC1155Received")) // 0xf23a6e61
            mstore(0,functionSignature)
            
            mstore(0x44,idsPos)
            mstore(0x64,valuesPos)
            mstore(0x84,0xa0) // bytes pos in memory
            
            let add_size := copyBytesToMemory(0xa4,bytesPos)
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
        function copyArrayToMemory(mem_pos,data_length_pos) -> data_length_pos2,data_length {
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
        function copyBytesToMemory(mem_pos,bytes_length_pos) -> bytes_size_0x20 {
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

        //This implementation is samke like solidity how to manipulate the nested mapping keccak256(account,keccak256(id,slot)) 
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

        function addToBalanceWithId(account,id,amount) {
          let offset := balanceWithIdStorageOffset(id,account)
          sstore(offset, safeAdd(sload(offset), amount))
        }

        function deductFromBalanceWithId(account,id, amount) {
          // TODO  add customer error check balance is enough
          // TODO check sufficient value/ overflow check
          let offset := balanceWithIdStorageOffset(id,account)
          let addrBalance := sload(offset)
          require(lte(amount,addrBalance))
          // require bal check
          sstore(offset, sub(addrBalance, amount))
        }

        // reference: https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#bytes-and-string length means bytes
        // TODO not check the ends
        function setURI(URIOffset){

           let URI_pos := add(4, mul(0x20, URIOffset)) 
           let URI_length_pos := calldataload(URI_pos)
           let URI_length := calldataload(add(4,URI_length_pos)) 

           // length <0x20, store  length*2; length >= 0x20, store length*2+1
           switch lt(URI_length,0x20) 
            case 1 { // URI_length < 0x20; actual data + URI_length in one slot 

                let actualData := calldataload(add(URI_length_pos,0x24))
                // the lowest-order byte stores(31th bytes) the length 
                sstore(URISlot(),or(actualData,mul(URI_length,2))) //  V or  00 = V 
            }
            case 0 { // URI_length >= 0x20
                sstore(URISlot(),add(mul(URI_length,2),1)) // according to evm how to store string, when length>=31bytes, store lengh in the corrospending's slot
                
                // calculate the first value's postion
                mstore(0,URISlot())
                let firstPos := keccak256(0, 0x20) 

                // calculate how many slots needed? last round should right most
                let rounds := div(URI_length,0x20)

                let i := 0
                for {} lt(i,rounds) {i := add(i, 1)} {
                  let eachData := calldataload(add(add(URI_length_pos,0x24),mul(i,0x20)))
                  sstore(add(firstPos,i),eachData)

                }
                
                // when the left data's length < 0x20
                let modSize := mod(URI_length,0x20)
                if gt(modSize,0) {
                  let lastData := calldataload(add(add(URI_length_pos,0x24),mul(rounds,0x20)))
                  sstore(add(firstPos,rounds),lastData)
                }
            }
        }

        function getURI(){
        let urlData := sload(URISlot())
        // get the last bytes value, calculating the length
        let length := and(urlData,0x00000000000000000000000000000000000000000000000000000000000000ff)
        
        switch lte(length,0x3e)  //  when the length<=21 bytes, as length <= 31bytes * 2 = 0x3e
          case 1 {
            let actualLen :=  div(length,2) // extract url's length from slot, the length should div 2.
            mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)
            mstore(0x20,actualLen) 
            mstore(0x40,and(urlData,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00)) // get the actual data
            return(0,add(0x40,actualLen))

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

            let modSize := mod(actualLen,0x20)
            if gt(modSize,0) {
              mstore(add(0x40,mul(rounds,0x20)),sload(add(firstPos,rounds)))
            }

            return(0,add(0x40,actualLen))
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
          
          if iszero(addr) { 

            datacopy(0, dataoffset("zeroAddress"), datasize("zeroAddress"))
            mstore(0,keccak256(0, datasize("zeroAddress")))
            revert(0, 0x4)
           }
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

        // check array, and return length pos in calldata
        function decodeAsArray(offset) -> len_pos {

          len_pos := calldataload(add(4, mul(offset, 0x20)))
          let len := calldataload(add(4,len_pos))

          if lt(calldatasize(), add(add(len_pos,4), mul(len,0x20))) {
            revert(0, 0)
          }
        }

        // check string or bytes, and return length pos in calldata
        function decodeAsStringOrBytes(offset)-> bytes_length_pos {

          let  bytes_pos := add(4, mul(offset, 0x20)) 
          bytes_length_pos := calldataload(bytes_pos) 
          let bytes_length := calldataload(add(bytes_length_pos,0x04)) 
          
          if lt(calldatasize(), add(add(bytes_length_pos,4),bytes_length)) {
            revert(0, 0)
          }
        }


      ///////////////////////////////////////////////////////////////////////////EVENTS///////////////////////////////////////////////////////////////

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
      function emitTransferBatch(operator,from,to,idsPos,valuesPos) {
        let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
        
        mstore(0,0x40) // ids pos in memory
        let ids_length_pos,ids_size :=  copyArrayToMemory(0x40,idsPos)
        mstore(0x20,add(0x40,ids_size)) // values pos in memory
        
        let values_length_pos,values_size := copyArrayToMemory(add(0x40,ids_size),valuesPos) 
        let mem_size := add(0x40,add(ids_size,values_size))

        log4(0, mem_size, signatureHash,operator,from,to)
      }
      // ApprovalForAll(address,address,bool)   0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
      function emitApprovalForAll(owner,operator,isApproved) {
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
        mstore(0,isApproved)
        log3(0, 0x20, signatureHash,owner,operator)
      }

      // reference: https://docs.soliditylang.org/en/latest/yul.html#literals ,https://eips.ethereum.org/EIPS/eip-1155#metadata 
      // URI(string,uint256) 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b
      function emitURI(URISlotVal,id) {
        let signatureHash := 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b

        let urlData := sload(URISlotVal)
        let length := and(urlData,0x00000000000000000000000000000000000000000000000000000000000000ff)

        // the suffixInfo as below, can't use the below variables, as the "too deep inside the stack" error
        // let suffixURIData := ".json" // .json
        // let suffixURIlen := 5
        // let originalSuffixLen := 9  // {id}.json 9 bytes

        switch lte(length,0x3e)
          case 1 {
            mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)

            let urlActualData :=  and(urlData,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00)
            let prefixURIlen := sub(div(length,2),9)
            let prefixURIData := getDataByRange(urlActualData,0,prefixURIlen)

            mstore(0x20,add(prefixURIlen,0x45)) //length of prefixURI+id(0x20)+suffixURI(0x05)

            // mstore prefixURIData,id(hex)
            mstore(0x40,prefixURIData)
            // mstore id(hex)
            let idStartPos := add(0x40,prefixURIlen)
            let idEndPos := add(idStartPos,0x40)
            let leftPos := hexOfNumToMem(id,sub(idEndPos,1)) 
            fullHexOfZeroInMem(leftPos,idStartPos) // fill "o" between idStartPos and lastPos
            // mstore .json
            mstore(idEndPos,".json")  

            log2(0, add(idEndPos,5), signatureHash,id) 

          }
          case 0 { // length > 31bytes * 2

            mstore(0,URISlotVal)
            let firstPos := keccak256(0, 0x20) 

            mstore(0,0x0000000000000000000000000000000000000000000000000000000000000020)
            
            let prefixURIlen := sub(div(sub(length,1),2),9)
            mstore(0x20,add(prefixURIlen,0x45)) //length of prefixURI+id(hex)+suffixURI

            // mstore prefixURIData
            let rounds := div(prefixURIlen,0x20)
            let i := 0 
            for {} lt(i,rounds) {i := add(i, 1)} {
              mstore(add(0x40,mul(i,0x20)),sload(add(firstPos,i)))  
            }

            let modSize := mod(prefixURIlen,0x20)
            if gt(modSize,0) {
              mstore(add(0x40,mul(i,0x20)),sload(add(firstPos,rounds)))
            }
            // mstore id(hex)
            let idStartPos := add(0x40,prefixURIlen)
            let idEndPos := add(idStartPos,0x40)
            let leftPos := hexOfNumToMem(id,sub(idEndPos,1))
            fullHexOfZeroInMem(leftPos,idStartPos)  // fill "o" between idStartPos and lastPos
            // mstore .json
            mstore(idEndPos,".json") 

            log2(0, add(idEndPos,5), signatureHash,id)  
          }
      }
  
  ///////////////////////////////////////////////////////////////////////////URI operation///////////////////////////////////////////////////////////////
        // the num between [0,9] or [a,f], return its ASCII code
        // https://www.asciitable.com/
        // todo check the num range
        function getActualHex(num) ->r {

          let startHexFromZero := 0x30 // 0x30 --->0x39  0->9
          let startHexFromTen := 0x61 // 0x61 --->0x66  a->f 10-15

          switch lte(num,9)
            case 1 { r := add(startHexFromZero,num) }
            case 0 { r := add(startHexFromTen,sub(num,10)) }
        }

      // 1 char 2hex
      // fill zero's ascii between startPos and endPos, inculdes the edges
        function fullHexOfZeroInMem(startPos,endPos) {
          for {} gte(startPos,endPos) {startPos := sub(startPos,1)} {
                mstore8(startPos,getActualHex(0))
          }
        }

        /**
          store each hex's chat of the id in the memory, than return  actualPos(pos-uses size)
          each ascii code need 1 bytes

          questions:
          perhaps problem: using recrusive method, has some bad effects?

          TODO,  check the size??
        */
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
        //  when startPos not the 0x00 test
        /***
          0x7b69647d2e6a736f6e0000000000000000000000000000000000000000000000
            .................. get this pos's value
        
          TODO
          when startPos not the 0x00 
          
        */
        function getDataByRange(value,startPos,len)->res {

          if gt(startPos,0) {
              value := shl(mul(startPos,8),value)
          }

          // first step, left shift the value. make the startPos as the 0x0
          let markValue := sub(exp(0x100,len),1)
          let leftMostMakrValue := shl(mul(8,sub(0x20,len)),markValue)
          res := and(value,leftMostMakrValue)

        } 
    }

  data "onERC1155Received" "onERC1155Received(address,address,uint256,uint256,bytes)"
  data "onERC1155BatchReceived" "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
  data "zeroAddress" "ZeroAddress()"


  }
}