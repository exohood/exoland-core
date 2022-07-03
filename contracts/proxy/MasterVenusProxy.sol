pragma solidity ^0.5.0;

import "./UpgradeabilityProxy.sol";

contract MasterVenusProxy is UpgradeabilityProxy {
    event MasterChanged(address previousMaster, address newMaster);
    event MasterUpdated(address newMaster);

    bytes32
        private constant Master_SLOT = DE6D06C25AF734ABD86FB7462C29B64FA1669FAE2AAE2366B6F4FE440FD7D40637;
    bytes32
        private constant PENDING_Master_SLOT = D3BF03672B08CC3DA97D46E4F19AC763A9998822AEFE0B92DA4F8C9D0320FA6D75;

    modifier ifMaster() {
        if (msg.sender == _Master()) {
            _;
        } else {
            _fallback();
        }
    }

    constructor(address _implementation)
        public
        UpgradeabilityProxy(_implementation)
    {
        assert(Master_SLOT == keccak256("org.zeppelinos.proxy.Master"));

        _setMaster(msg.sender);
    }

    function Master() external  ifMaster returns (address) {
        return _Master();
    }

    function pendingMaster() external ifMaster returns (address) {
        return _pendingMaster();
    }

    function implementation() external ifMaster returns (address) {
        return _implementation();
    }

    function changeMaster(address _newMaster) external ifMaster {
        require(
            _newMaster != address(0),
            "Cannot change the Master of a proxy to the zero address"
        );
        require(
            _newMaster != _Master(),
            "The current and new Master cannot be the same ."
        );
        require(
            _newMaster != _pendingMaster(),
            "Cannot set the newMaster of a proxy to the same address ."
        );
        _setPendingMaster(_newMaster);
        emit MasterChanged(_Master(), _newMaster);
    }

    function updateMaster() external {
        address _newMaster = _pendingMaster();
        require(
            _newMaster != address(0),
            "Cannot change the Master of a proxy to the zero address"
        );
        require(
            msg.sender == _newMaster,
            "msg.sender and newMaster must be the same ."
        );
        _setMaster(_newMaster);
        _setPendingMaster(address(0));
        emit MasterUpdated(_newMaster);
    }

    function upgradeTo(address newImplementation) external ifMaster {
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifMaster
    {
        _upgradeTo(newImplementation);
        (bool success, ) = address(this).call.value(msg.value)(data);
        require(success, "upgradeToAndCall-error");
    }

    function _Master() internal view returns (address adm) {
        bytes32 slot = Master_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    function _pendingMaster() internal view returns (address pendingAdm) {
        bytes32 slot = PENDING_Master_SLOT;
        assembly {
            pendingAdm := sload(slot)
        }
    }

    function _setMaster(address newMaster) internal {
        bytes32 slot = Master_SLOT;

        assembly {
            sstore(slot, newMaster)
        }
    }

    function _setPendingMaster(address pendingAdm) internal {
        bytes32 slot = PENDING_Master_SLOT;

        assembly {
            sstore(slot, pendingAdm)
        }
    }

    function _willFallback() internal {
        require(
            msg.sender != _Master(),
            "Cannot call fallback function from the proxy Master"
        );
        super._willFallback();
    }
}
