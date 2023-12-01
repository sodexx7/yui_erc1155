
// doing YUI ERC20 yui udemy course familiar with

// 1)define data structure 
// 2)basic mint/ transfer


// update _balances    
//         balances[id][from] = fromBalance - value;
//         _balances[id][to] += value;


// 1. Constructor
//     set the _setURI, my implementation, here 

// 2. when emit the event: event URI(string _value, uint256 indexed _id).
//     mint new id?

// 3. data structure 
//     mapping(uint256 id => mapping(address account => uint256)) private _balances;
//     mapping(address account => mapping(address operator => bool)) private _operatorApprovals;


// 4. other functions

//     Autoher check
//     safeTransferFrom when from =0x00 . mint , to =0x00 burn
//     safeBatchTransferFrom

//     update the data structure


//     update. based on the array. 


// 5.reference
//   YUI how to deal with the string


// ? how the below code manipulate the memory???

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

        // Dispatcher  doing

        // TODO toAdd mint, BathchMint, should only the owner has the right calling it?

        // mint, batchMint for test cases ???
        switch selector() 
        case 0x731133e9 /* mint(address,uint256,uint256,bytes)*/ {
          mint(decodeAsAddress(0),convertUintToArrayInMemory(1),convertUintToArrayInMemory(2),convertArrayToMemory(3))
          returnTrue()
        }
        case 0xb48ab8b6 /* batchMint(address,uint256[],uint256[],bytes)*/ {
          // array in memory no value? should mannuly operate, 

          // should I mannly operate the array to the memory?
          // check when  call like this batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data)
            // memory no data?
          // consistant ?
       
          batchMint(decodeAsAddress(0),convertArrayToMemory(1),convertArrayToMemory(2),convertArrayToMemory(3))
          returnTrue()
        }
        case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)"  */ {
          safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), convertUintToArrayInMemory(2),convertUintToArrayInMemory(3),convertArrayToMemory(4))
          returnTrue()
        }
        case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
          returnUint(balanceOf(decodeAsAddress(0),decodeAsUint(1)))
        }
        case 0x2eb2c2d6 /* safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)  */ {
          safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1),convertArrayToMemory(2),convertArrayToMemory(3),convertArrayToMemory(4))
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

        function mint(to,idsPos,valuesPos,bytesPos) {
          //how to set address(0) in YUI 
          // safeTransferFrom(0,to,idsPos,valuesPos)
          update(0,to,idsPos,valuesPos)

        }

        // how the array transfer during the funtion call funtion
        function batchMint(to,idsPos,valuesPos,bytesPos) {
          // safeBatchTransferFrom(0x00,to,idsPos,valuesPos)
          safeBatchTransferFrom(0,to,idsPos,valuesPos,bytesPos)
        }

        function safeTransferFrom(from,to,idsPos,valuesPos,bytesPos) {

          update(from,to,idsPos,valuesPos)
        
        }

        function safeBatchTransferFrom(from,to,idsPos,valuesPos,bytesPos) {

          update(from,to,idsPos,valuesPos)
        
        }

        // update all values, cover singal/batch
        // This should put in the slot access group
        function update(from,to,idsPos,valuesPos) {

          let ids_length := mload(idsPos)

          // TODO when ids length !== values length ,should get the min length
         
          let i := 0
          for {} lt(i,ids_length) {i := add(i, 1)} {
              // doing
              let id := mload(add(add(idsPos,0x20),mul(i,0x20)))
              let value := mload(add(add(valuesPos,0x20),mul(i,0x20)))

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
              // todo emit event
          }
        }

       function setApprovalForAll(operator,isApproved) {

        // caller???  TODO check the caller is the owner??
        let offset := operatorApprovalStorageOffset(caller(),operator)
        sstore(offset, safeAdd(sload(offset), isApproved))

       }



        /**
        functions not in the switch, can take it as the internal funcitons
        
        */

        // doing
        // update functions/ check functions
        // solve the possible conflict problem

       

        // Cover batch and signal transaction
        // ?? should use which way. for... check.. update

        

  

         /* -------- storage layout ---------- */
        // should the check the implementation maybe has some conflict?
        
        function balancesPos() -> p { p := 0 }
        function operatorApprovalsPos() -> p { p := 1 }


        // This implementation is samke like solidity how to manipulate the nested mapping keccak256(account,keccak256(id,slot)) 
        function balanceWithIdStorageOffset(id, account) -> offset {
           
           mstore(0, id)
           mstore(0x20, balancesPos())
           
           mstore(0x20,keccak256(0, 0x40)) 
           mstore(0, account)
           offset := keccak256(0, 0x40)
        }
        function operatorApprovalStorageOffset(account, operator) -> offset {
            mstore(0, account)
            mstore(0x20, operator)
            offset := keccak256(0, 0x40)
        }

      //   // Now only support singal safeTransferFrom, only singal mint 
      //   // address from, address to, uint256[] memory ids, uint256[] memory values
      //   /***
      //     todo
      //     1) batch test
      //     2) all situations check
      //     3) add event
      //   ***/
       

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



      /* -------- storage access ---------- */

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


      /* ---------- calldata encoding functions ---------- */
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

      // address format: 0x + "0"*20+"0"*12
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

      /* -------- convert calldata to memory ---------- */
      /***
      Copy array in calldata to the memory
      1: array in calldata: place+length_value+each value
      2: copy array's length value following each array's value in the memory
      3. return the position, which points to the length value's position in memory
      ***/
      // convert one calldata type the array in the memory, and return the start_position(length value)
      function convertArrayToMemory(offset) -> len_position {
        
        // TODO copy the calldata into the memory, before copy the data into the memory, should check?

        // calculate the array's  lens_pos in the calldata
        let start_pos_loc := add(4, mul(offset, 0x20)) 
        let len_pos := calldataload(start_pos_loc)
        let len_pos_calldata :=  add(4,len_pos)

        let size := calldataload(len_pos_calldata) 
        len_position := msize()
        //TODO should check the msize has some side effects?
        calldatacopy(len_position,len_pos_calldata,mul(add(size,1),0x20))
        
      }

      // convert the uint param in calldata to the array in memory, the aim is to keep consistant with the uint[] in memory
      function convertUintToArrayInMemory(offset) -> len_position {
        let v := decodeAsUint(offset)

        len_position := msize()
        mstore(len_position,0x01)
        mstore(add(len_position,0x20),v)
        
      }



      


        // todo, especially for the array  
        /***
        function balanceOf(accounts,ids) -> bal {
            bal := sload(balanceWithIdStorageOffset(id,account))
        }
        **/

    }

    // data "Message" "test string test stringtest stringtest stringtest string test string test stringtest stringtest stringtest string"
  }


  //     data structure 
  //     mapping(uint256 id => mapping(address account => uint256)) private _balances;
  //     mapping(address account => mapping(address operator => bool)) private _operatorApprovals;


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
