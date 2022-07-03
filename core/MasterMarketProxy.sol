/*
/***
*     ______           __                    __
*    / _____  ______  / /_  ____  ____  ____/ /
*   / __/ | |/_/ __ \/ __ \/ __ \/ __ \/ __  / 
*  / /____>  </ /_/ / / / / /_/ / /_/ / /_/ /  
* /_____/_/|_|\____/_/ /_/\____/\____/\__,_/   
*                                             
*   
*    
* https://www.exohood.com
*
* MIT License
* ===========
*
* Copyright (c) 2021 exohood
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.0;

contract Proxy {
    function() external payable {
        _fallback();
    }

    function _implementation() internal view returns (address);

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize)

            let result := delegatecall(
                gas,
                implementation,
                0,
                calldatasize,
                0,
                0
            )
            returndatacopy(0, 0, returndatasize)

            switch result
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }

    function _willFallback() internal {}

    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

// File: contracts/proxy/MasterVenusProxy.sol

pragma solidity ^0.5.0;


library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract MasterVenusProxy is Proxy {
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

// File: contracts/proxy/AdminMasterVenusProxy.sol

pragma solidity ^0.5.0;


contract AdminMasterVenusProxy is MasterVenusProxy {
    event AdminChanged(address previousAdmin, address newAdmin);
    event AdminUpdated(address newAdmin);

    bytes32
        private constant ADMIN_SLOT = DE6D06C25AF734ABD86FB7462C29B64FA1669FAE2AAE2366B6F4FE440FD7D40637;
    bytes32
        private constant PENDING_ADMIN_SLOT = D3BF03672B08CC3DA97D46E4F19AC763A9998822AEFE0B92DA4F8C9D0320FA6D75;

    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    constructor(address _implementation)
        public
        MasterVenusProxy(_implementation)
    {
        assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

        _setAdmin(msg.sender);
    }

    function admin() external  ifAdmin returns (address) {
        return _admin();
    }

    function pendingAdmin() external ifAdmin returns (address) {
        return _pendingAdmin();
    }

    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    function changeAdmin(address _newAdmin) external ifAdmin {
        require(
            _newAdmin != address(0),
            "Cannot change the admin of a proxy to the zero address"
        );
        require(
            _newAdmin != _admin(),
            "The current and new admin cannot be the same ."
        );
        require(
            _newAdmin != _pendingAdmin(),
            "Cannot set the newAdmin of a proxy to the same address ."
        );
        _setPendingAdmin(_newAdmin);
        emit AdminChanged(_admin(), _newAdmin);
    }

    function updateAdmin() external {
        address _newAdmin = _pendingAdmin();
        require(
            _newAdmin != address(0),
            "Cannot change the admin of a proxy to the zero address"
        );
        require(
            msg.sender == _newAdmin,
            "msg.sender and newAdmin must be the same ."
        );
        _setAdmin(_newAdmin);
        _setPendingAdmin(address(0));
        emit AdminUpdated(_newAdmin);
    }

    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeTo(newImplementation);
        (bool success, ) = address(this).call.value(msg.value)(data);
        require(success, "upgradeToAndCall-error");
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    function _pendingAdmin() internal view returns (address pendingAdm) {
        bytes32 slot = PENDING_ADMIN_SLOT;
        assembly {
            pendingAdm := sload(slot)
        }
    }

    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            sstore(slot, newAdmin)
        }
    }

    function _setPendingAdmin(address pendingAdm) internal {
        bytes32 slot = PENDING_ADMIN_SLOT;

        assembly {
            sstore(slot, pendingAdm)
        }
    }

    function _willFallback() internal {
        require(
            msg.sender != _admin(),
            "Cannot call fallback function from the proxy admin"
        );
        super._willFallback();
    }
}

// File: contracts/market/exolandmarket.sol

pragma solidity ^0.5.5;


contract exolandmarket is MasterVenusProxy {
    constructor(address _implementation)
        public
        MasterVenusProxy(_implementation)
    {}

    // Allow anyone to view the implementation address
    function proxyImplementation() external view returns (address) {
        return _implementation();
    }

    function proxyAdmin() external view returns (address) {
        return _admin();
    }
}
