pragma solidity ^0.5.5;


import "../interface/IERC20.sol";
import "../library/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../interface/EXOArtToken.sol";
import "../library/EXOGuard.sol";

contract EXOArtFactory is EXOGuard, IERC721Receiver{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct EXOArt {
        uint256 id;
        uint256 createdTime;
        uint256 blockNum;
        uint256 tokenAmount;
        address tokenAddress;
        address author;
        string resName;
    }

    event EXOArtAdded(
        uint256 indexed id,
        uint256 createdTime,
        uint256 blockNum,
        uint256 tokenAmount,
        address tokenAddress,
        address author,
        string resName
    );

    event EXOArtBurn(
        uint256 indexed id,
        address tokenAddress,
        uint256 tokenAmount
    );

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);


        // --- Data ---
    bool private initialized; // Flag of initialize data

    // for minters
    mapping(address => bool) public _minters;

    mapping(uint256 => EXOArt) public _exoarts;

    uint256 public _exoArtId = 0;

    uint256 public _burnTime = 30 days;
    EXOArtToken public _exoArt = EXOArtToken(0x0);

    IERC20 public _rewardToken = IERC20(0x0);
    uint256 public _rewardAmount = 100 finney;

    IERC20 public _costToken = IERC20(0x0);
    uint256 public _costAmount = 1 ether;
    address public _costAddress = address(0x0);


    bool public _isUserStart = false;
    bool public _hasReward = false;

    address public _governance;

    mapping(string => address) _resMap; 

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        _governance = tx.origin;
    }


    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }


    // --- Init ---
    function initialize(
        address EXOArtToken,
        address rewardToken,
        uint256 rewardAmount,
        address costToken,
        uint256 costAmount,
        address costAddress,
        uint256 burnTime,
        bool isUserStart,
        bool hasReward
    ) public {
        require(!initialized, "initialize: Already initialized!");
        require(costAddress != address(0x0) , "costAddress can't be null");

        _governance = msg.sender;
    
        _exoArt = EXOArtToken(exoArtToken);
        
        _rewardToken = IERC20(rewardToken);
        _rewardAmount = rewardAmount;

        _costToken = IERC20(costToken);
        _costAmount = costAmount;
        _costAddress = costAddress;

        _burnTime = burnTime;
        _isUserStart = isUserStart;
        _hasReward = hasReward;

        initReentrancyStatus();
        initialized = true;
    }

    function setGegoArtId(uint256 id) public onlyGovernance {
        _exoArtId = id;
    }


    function setRewardAmount(uint256 value) public onlyGovernance{
        _rewardAmount =  value;
    }

    function setUserStart(bool start) public onlyGovernance {
        _isUserStart = start;
    }

    function setHasReward(bool has) public onlyGovernance {
        _hasReward = has;
    }

    function setBurnTime(uint256 burnTime) public onlyGovernance {
        _burnTime = burnTime;
    }

    function addMinter(address minter) public onlyGovernance {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyGovernance {
        _minters[minter] = false;
    }

    function setResMap(string memory resName, address addr) public onlyGovernance {
        _resMap[resName] = addr;
    }

    /**
     * @dev set exo contract address
     */
    function setEXOArtContract(address addr)  public  
        onlyGovernance{
        _exoArt = EXOArtToken(addr);
    }

    /**
     * @dev set dandy contract address
     */
    function setRewardContract(address addr)  public  
        onlyGovernance{
        _rewardToken = IERC20(addr);
    }


    function getEXOArt(uint256 tokenId)
        external view
        returns (
            uint256 createdTime,
            uint256 blockNum,
            uint256 tokenAmount,
            address tokenAddress,
            address author,
            string memory resName
        )
    {
        EXOArt storage EXOArt = _exoArts[tokenId];
        require(EXOArt.id > 0, "not exist");
        createdTime = exoArt.createdTime;
        blockNum = exoArt.blockNum;
        tokenAmount = exoArt.tokenAmount;
        tokenAddress = exoArt.tokenAddress;
        author = EXOArt.author;
        resName = EXOArt.resName;
    }

    function mint(string memory resName, address to,  address tokenAddress, uint256 tokenAmount) public 
        nonReentrant
        returns (uint256) {
        require(_isUserStart || _minters[msg.sender]  , "can't mint");
        require(_resMap[resName] == address(0x0), "resName has existed");

        uint256 realAmount = 0;
        if( tokenAddress != address(0x0) ){
            require(tokenAmount > 0, "tokenAmount must > 0");

            IERC20 token = IERC20(tokenAddress);
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
            uint256 balanceEnd = token.balanceOf(address(this));
            realAmount = balanceEnd.sub(balanceBefore);

            _costToken.safeTransferFrom(msg.sender, _costAddress, _costAmount);
        }
        _exoArtId++ ;

        EXOArt memory exoArt;
        exoArt.id = _exoArtId;

        exoArt.blockNum = block.number;
        exoArt.createdTime =  block.timestamp ;
        exoArt.tokenAddress = tokenAddress;
        exoArt.tokenAmount = realAmount;
        exoArt.author = to;
        exoArt.resName = resName;

        _exoArts[_exoArtId] = exoArt;

        _exoArt.mint(to, _exoArtId);
        _resMap[resName] = to;

        emit EXOArtAdded(
            exoArt.id,
            exoArt.blockNum,
            exoArt.createdTime,
            exoArt.tokenAmount,
            exoArt.tokenAddress,
            exoArt.author,
            exoArt.resName
        );

        if(_hasReward){
            _rewardToken.mint(msg.sender, _rewardAmount); 
        }

        return _exoArtId;
    }


    function burn(uint256 tokenId) 
        external nonReentrant
        returns ( bool ) {
        exoArt memory exoArt = _exoArts[tokenId];
        require(exoArt.id > 0, "not exist");

        if(!_minters[msg.sender]){
            require( (block.timestamp - exoArt.createdTime) >= _burnTime, "< burnTime"  );
        }

        // transfer nft to contract
        _exoArt.safeTransferFrom(msg.sender, address(this), tokenId);
        _exoArt.burn(tokenId);

        if( exoArt.tokenAddress != address(0x0) && exoArt.tokenAmount > 0 ){
            IERC20 token = IERC20(gegoArt.tokenAddress);
            token.safeTransfer(msg.sender, exoArt.tokenAmount);
        }

        _resMap[EXOArt.resName] = address(0x0);

        // set burn flag
        emit EXOArtBurn(EXOArt.id, EXOArt.tokenAddress, EXOArt.tokenAmount);
        EXOArt.id = 0;

        delete _exoArts[tokenId];
        
        return true;
    }

    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
