//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/PriceConverter.sol";

error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author
 * @notice
 * @dev
 */
contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't Send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;

            //reset the array
            funders = new address[](0);

            //withdraw the funds
            (bool callSuccess, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
            require(callSuccess, "Call Failed");
        }
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
