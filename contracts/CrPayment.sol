// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CrPayment is Ownable {
    using Address for address payable;

    uint256 public constant VERSION = 1;
    uint256 public constant BASIS_POINTS = 10000;

    address public feeTo;
    uint256 public platformFeeBasisPoints;

    event FeeToAddressSet(address _feeTo);
    event PlatformFeeBasisPointsSet(uint256 _platformFeeBasisPoints);

    event Payment(
        uint256 indexed _sessionId,
        address indexed _merchant,
        address _token,
        uint256 _amount
    );

    /**
     * @dev Constructor
     * @param _feeTo The address to receive the platform fee
     * @param _platformFeeBasisPoints The platform fee basis points
     * @notice The platform fee basis points must be less than 10000
     * @notice The fee to address must not be the zero address
     */
    constructor(address _feeTo, uint256 _platformFeeBasisPoints) {
        require(
            _platformFeeBasisPoints < BASIS_POINTS,
            "Invalid platform fee basis points"
        );
        require(_feeTo != address(0), "Invalid fee to address");

        feeTo = _feeTo;
        platformFeeBasisPoints = _platformFeeBasisPoints;
    }

    /**
     * @dev Set the fee to address
     * @param _feeTo The address to receive the platform fee
     * @notice The fee to address must not be the zero address
     */
    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), "Invalid fee to address");
        feeTo = _feeTo;
        emit FeeToAddressSet(_feeTo);
    }

    /**
     * @dev Set the platform fee basis points
     * @param _platformFeeBasisPoints The platform fee basis points
     * @notice The platform fee basis points must be less than 10000
     */
    function setPlatformFeeBasisPoints(
        uint256 _platformFeeBasisPoints
    ) external onlyOwner {
        require(
            _platformFeeBasisPoints < BASIS_POINTS,
            "Invalid platform fee basis points"
        );
        platformFeeBasisPoints = _platformFeeBasisPoints;
        emit PlatformFeeBasisPointsSet(_platformFeeBasisPoints);
    }

    /**
     * @dev Pay the merchant
     * @param _sessionId The payment session id
     * @param _merchant The merchant address
     * @param _token The token address
     * @param _amount The amount of tokens
     */
    function pay(
        uint256 _sessionId,
        address _merchant,
        address _token,
        uint256 _amount
    ) external payable {
        uint256 feeAmount = (_amount * platformFeeBasisPoints) / BASIS_POINTS;
        if (_token == address(0)) {
            require(msg.value == _amount, "Invalid price");
            payable(feeTo).sendValue(feeAmount);
            payable(_merchant).sendValue(_amount - feeAmount);
        } else {
            IERC20(_token).transferFrom(msg.sender, feeTo, feeAmount);
            IERC20(_token).transferFrom(
                msg.sender,
                _merchant,
                _amount - feeAmount
            );
        }

        emit Payment(_sessionId, _merchant, _token, _amount);
    }
}
