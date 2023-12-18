// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "./tokens/ERC1155TokenReceiver.sol";

interface ERC1155_YUI {

    function mint(address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function burn(address from, uint256 _id, uint256 _value) external;

    function batchBurn(address _to, uint256[] memory _ids, uint256[] memory _values) external;
    function batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data) external;

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function setURI(string memory URI) external;
    function getURI() external returns (string memory);
    function updateURIWithTokenId(uint256 id,string memory URI) external;
  
}


contract ERC1155_URI_YUI is DSTestPlus {

    YulDeployer yulDeployer = new YulDeployer();

    ERC1155_YUI token;

    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256)) public userTransferOrBurnAmounts;

    function setUp() public {
        token = ERC1155_YUI(yulDeployer.deployContract("ERC1155_YUI"));
    }

     event URI(string  _value, uint256 indexed _id);

     function testEmitURI() public {
         // Doing test string "0"
         // string memory url = "000000000000000000000000000000000000000000001d7c"; // <0x20
         // console.log(bytes(url).length);
 
         string memory url = "https://cdn-domain/"; // <0x20
         // string memory url = "https://abcdn-domain/"; // >=0x20 30bytes
         // string memory url = "https://aaaabcdn-domain/"; // >=0x20 31bytes
         // string memory url = "https://aassdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxaabcdn-domain/"; // >=0x20 32bytes
 
         string memory suffixURI = "{id}.json";
         string memory originalFullURI = string.concat(url, suffixURI);
 
         // token.setURI(originalFullURI);
         // token.getURI();
         console.log(originalFullURI);
         // console.log(bytes(originalFullURI).length);
 
         // string memory checkURIwithId = string.concat(url, toHexString(uint256(314592), 32), ".json");
 
         hevm.expectEmit(true, true, false, true);
         emit URI(originalFullURI,314592);
         token.updateURIWithTokenId(314592,originalFullURI);
     }
 
 
 
     // how to limit the string range
     function testEmitURI(
         string memory url,
         uint256 id
     ) public {
        
         console.log(url);
         string memory suffixURI = "{id}.json";
         string memory originalFullURI = string.concat(url, suffixURI);
 
         hevm.expectEmit(true, true, false, true);
         emit URI(originalFullURI, id);
         token.updateURIWithTokenId(id,originalFullURI);
     }
 
    
 
   
     function testSetURI() public {
         // when len(URI) <0x20
         // string memory url = "https://cdn-domain/{id}.json"; // <0x20
         // string memory url = "https://abcdn-domain/{id}.json"; // >=0x20 30bytes
         // string memory url = "https://aabcdn-domain/{id}.json"; // >=0x20 31bytes  take  1hex as 1 bytes
         // string memory url = "https://aaabcdn-domain/{id}.json"; // >=0x20 32bytes   TODO check when 1 hex == 1 bytes??
         string memory url = "https://aaabcdn-domain/{id}.jsonhttps://aaabcdn-domain/{id}.json"; // >=0x20 32bytes   TODO check when 1 hex == 1 bytes??
 
         uint256 test = bytes("{id}.json").length;
         console.log("test", test);
 
         token.setURI(url);
         // reference: https://docs.soliditylang.org/en/latest/types.html#bytes-and-string-as-arrays
         uint256 len = bytes(url).length;
         console.log("len", len);
         if (len < 31) {
             // when len(URI) >= 0x20
             console.log("slot key:2");
             console.log("slot value");
             console.logBytes32(hevm.load(address(token), bytes32(uint256(2)))); // pos slot store the length
         } else {
             console.log("slot pos value");
             console.logBytes32(hevm.load(address(token), bytes32(uint256(2))));
 
             uint256 rounds = len / 32;
             bytes32 firstPos = keccak256(abi.encode(bytes32(uint256(2))));
 
             for (uint256 i = 0; i < rounds; i++) {
                 console.log("the ", i, "th key");
                 console.logBytes32(bytes32(uint256(firstPos) + i));
                 console.log("the ", i, "th value");
                 console.logBytes32(hevm.load(address(token), bytes32(uint256(firstPos) + i)));
             }
 
             uint256 modSize = len % 32;
             if (modSize > 0) {
                 console.log("the ", rounds, "th key");
                 console.logBytes32(bytes32(uint256(firstPos) + rounds));
                 console.log("the ", rounds, "th value");
                 console.logBytes32(hevm.load(address(token), bytes32(uint256(firstPos) + rounds)));
             }
         }
 
         string memory URIresult = token.getURI();
         console.log(URIresult);
         // assertEq(url,URIresult);
     }
 
     // specifical string url how to limit the string range???
     function testSetURI(string memory url) public {
 
         token.setURI(url);
         // reference: https://docs.soliditylang.org/en/latest/types.html#bytes-and-string-as-arrays
         uint len = bytes(url).length;
         if(len < 31){
           // when len(URI) >= 0x20
              console.log("slot key:2");
              console.log("slot value");
             console.logBytes32(hevm.load(address(token),bytes32(uint(2)))); // pos slot store the length
         } else {
             console.log("slot pos value");
             console.logBytes32(hevm.load(address(token),bytes32(uint(2))));
 
             uint rounds = len/32;
             bytes32 firstPos = keccak256(abi.encode(bytes32(uint(2))));
 
             for(uint i =0;i< rounds;i++){
                 console.log("the ",i,"th key");
                 console.logBytes32(bytes32(uint(firstPos)+i));
                 console.log("the ",i,"th value");
                 console.logBytes32(hevm.load(address(token),bytes32(uint(firstPos)+i)));
             }
 
             uint modSize = len%32;
             if(modSize > 0 ){
                 console.log("the ",rounds,"th key");
                 console.logBytes32(bytes32(uint(firstPos)+rounds));
                 console.log("the ",rounds,"th value");
                 console.logBytes32(hevm.load(address(token),bytes32(uint(firstPos)+rounds)));
             }
         }
 
         string memory URIresult = token.getURI();
         // console.log(URIresult);
         assertEq(url,URIresult);
 
     }

}
