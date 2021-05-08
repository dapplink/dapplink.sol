pragma solidity 0.5.0;


contract Dapplink {
    
    string  public   name;
    string  public   symbol;
    string  internal nft_base_uri;
    uint256 public   totalSupply;
    
    address payable public admin;
    
    uint256 public fee_mint;
    uint256 public fee_transfer;
    uint256 public fee_approve;
    
    struct filesystem {
        address file_sha;	
        string  file_mime;
        uint    n_chunks;
    } 
    
    mapping( address => uint256 ) internal balances;
    mapping( uint256 => address ) internal owners;
    mapping( uint256 => address ) internal allowance;
    mapping( uint256 => string  ) public   domains;
    mapping( uint256 => uint256 ) public   index_id;
    mapping( uint256 => bool    ) public   closed;
    
    mapping(  uint256 => mapping( address => filesystem )  ) public files;
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    // TODO event close
    
    event Chunk
        (
            uint256 indexed tokenId,
            address indexed file_sha,
            uint    indexed chunk_index,
            bytes           chunk_data
        ); 
    
    constructor () public {
        name         = "Dapplink";
        symbol       = "DLK";
        admin        = msg.sender;
        nft_base_uri = ".dapplink.io";
        totalSupply  = 0;
    }
    
    function mint( string memory _domain ) public payable {
        require ( msg.value >= fee_mint );
        uint256 domain_hash = uint256(keccak256(abi.encodePacked(_domain)));
        uint256 domain_match = uint256(keccak256(abi.encodePacked(domains[domain_hash])));
        require( domain_match != domain_hash );
        balances[ msg.sender ]++;
        owners[ domain_hash ] = msg.sender;
        domains[ domain_hash ] = _domain;
        totalSupply++;
        index_id[ totalSupply ] = domain_hash;
        emit Transfer( 0x0000000000000000000000000000000000000000, msg.sender, domain_hash );
    }
    
    function balanceOf( address _owner ) public view returns ( uint256 ) {
        return balances[_owner];
    }
    
    function ownerOf( uint256 _tokenId ) public view returns ( address ) {
        require( _tokenId != 0 );
        return owners[_tokenId];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable {
        transferFrom(_from, _to, _tokenId);
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        }
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from,_to,_tokenId,"");
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        address owner = ownerOf( _tokenId );
        require ( msg.value >= fee_transfer );
        require ( owner == msg.sender  || allowance[_tokenId] == msg.sender );
        require ( owner == _from );
        require ( _to != 0x0000000000000000000000000000000000000000 );
        emit Transfer( _from, _to, _tokenId );
        owners[ _tokenId ] = _to;
        balances[ _from ]--;
        balances[ _to ]++;
        if(  allowance[ _tokenId ] != 0x0000000000000000000000000000000000000000  ) {
            delete allowance[ _tokenId ];
        }
    }
    
    function approve( address _approved, uint256 _tokenId ) external payable {
        address owner = ownerOf( _tokenId );
        require( owner == msg.sender, "You have no rights" );
        require ( msg.value >= fee_approve );
        allowance[ _tokenId ] = _approved;
        emit Approval( owner, _approved, _tokenId );
    }
    
    function setApprovalForAll( address _operator, bool _approved ) external {
        require( false, "setApprovalForAll method is deprecated");
    }
    
    function getApproved( uint256 _tokenId ) external view returns ( address ) {
        require( _tokenId != 0 );
        return allowance[_tokenId];
    }
    
    function isApprovedForAll( address _owner, address _operator ) external view returns ( bool ) {
        return false;
    }
    
    // function name() external view returns (string _name) {}
    
    // function symbol() external view returns (string _symbol);
    
    function tokenURI( uint256 _tokenId ) public view returns (string memory) {
        return string(abi.encodePacked( "https://", domains[_tokenId], nft_base_uri, "/nft.json" ));
    }
    
    // function totalSupply() external view returns (uint256) {}

    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require ( _index <= totalSupply );
        return index_id[ _index ];
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 n = balances[_owner];
        uint256[] memory ids = new uint256[](n);
        uint256 push_pointer = 0;
        for ( uint256 i = 1; i <= totalSupply; i++ ) {
            if ( owners[index_id[i]] == _owner ) {
                ids[ push_pointer ] = index_id[ i ];
                push_pointer++;
            }
        }
        return ids;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require( _index <= balanceOf(_owner) );
        uint256[] memory ids = tokensOfOwner(_owner);
        return ids[_index-1];
    }
    
    function supportsInterface( bytes4 interfaceID ) external view returns ( bool ) {
        if ( interfaceID == 0x80ac58cd ) return true; // ERC721
        if ( interfaceID == 0xffffffff ) return true; // ERC165
        if ( interfaceID == 0x5b5e139f ) return true; // ERC721Metadata
        if ( interfaceID == 0x780e9d63 ) return true; // ERC721Enumerable
        return false;
    }
    
    modifier admin_only
        {
            require( msg.sender == admin );
            _;
        } 
        
    function change_admin
        (
            address payable new_admin
        ) 
        external admin_only
        {
            admin = new_admin;
        } 
        
    function set_mint_fee
        (
            uint256 new_mint_fee
        ) 
        external admin_only
        {
            fee_mint = new_mint_fee;
        }
        
    function set_transfer_fee
        (
            uint256 new_transfer_fee
        ) 
        external admin_only
        {
            fee_transfer = new_transfer_fee;
        }
        
    function set_approve_fee
        (
            uint256 new_approve_fee
        ) 
        external admin_only
        {
            fee_approve = new_approve_fee;
        }
        
    function withdraw
        () 
        external admin_only
        {
            admin.send(  address( this ).balance  );
        }       
        
    modifier token_owner_only( uint256 tokenId )
        {
            require( msg.sender == ownerOf( tokenId ) );
            require( closed[ tokenId ] == false );
            _;
        } 
        
    function upload_chunk
        (
            uint256        tokenId,
            address        file_sha,
            uint           chunk_index,
            bytes   memory chunk_data
        ) 
        public token_owner_only( tokenId )
        {
            emit Chunk (
                tokenId,
                file_sha, 
                chunk_index,
                chunk_data
            );
        } 
        
    function link
        (
            uint256         tokenId,
            address         pathname_sha,
            address         file_sha,
            string   memory file_mime,
            uint            n_chunks
        ) 
        public token_owner_only( tokenId )
        {
            files[ tokenId ][ pathname_sha ].file_sha  = file_sha;
            files[ tokenId ][ pathname_sha ].file_mime = file_mime;
            files[ tokenId ][ pathname_sha ].n_chunks  = n_chunks;
        } 
        
    function unlink
        (
            uint256 tokenId,
            address pathname_sha
        )
        public token_owner_only( tokenId )
        {
            delete files[ tokenId ][ pathname_sha ];
        }
        
    function close
        (
            uint256 tokenId
        )
        public token_owner_only( tokenId )
        {
            closed[ tokenId ] = true;
        }

}

interface ERC721TokenReceiver {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);

}
