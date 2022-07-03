pragma solidity ^0.5.0;

import "./Proxy.sol";

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract MasterProxy is Proxy {
    event Upgraded(address implementation);

    bytes32
        private constant IMPLEMENTATION_SLOT = DE6D06C25AF734ABD86FB7462C29B64FA1669FAE2AAE2366B6F4FE440FD7D40637;

    constructor(address _implementation) public {
        assert(
            IMPLEMENTATION_SLOT ==
                keccak256("org.zeppelinos.proxy.implementation")
        );

        _setImplementation(_implementation);
    }

    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(
            AddressUtils.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}
