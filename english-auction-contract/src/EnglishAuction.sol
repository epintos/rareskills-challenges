// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title EnglishAuction
 * @author Esteban Pintos
 * @notice Contract that allows Sellers to deposit an NFT and start an auction. Users can bid on the NFT and the highest
 * bid wins the auction. If the reserve price is not met after the deadline, the users can withdraw their bid. If the
 * reserve price is met, the seller can end the auction and the highest bidder gets the NFT and the seller gets the ETH.
 */
contract EnglishAuction {
    /// ERRORS
    error EnglishAuction__AddressCannotBeZero();
    error EnglishAuction__AuctionDoesNotExist();
    error EnglishAuction__AuctionDeadlineCannotBeInThePast();
    error EnglishAuction__ReservePriceCannotBeZero();
    error EnglishAuction__DepositLowerThanReservePrice();
    error EnglishAuction__AuctionHasEnded();
    error EnglishAuction__BidderHasAlreadyBid();
    error EnglishAuction__AuctionHasNotEnded();
    error EnglishAuction__BidderHasNotBid();
    error EnglishAuction__SenderIsNotSeller();
    error EnglishAuction__TransferFailed();
    error EnglishAuction__AuctionReservePriceNotMet();
    error EnglishAuction__ReceiverIsNotCurrentContract();
    error EnglishAuction__SellerCannotBid();

    /// TYPE DECLARATIONS
    struct Auction {
        bool exists;
        address seller;
        address nftAddress;
        uint256 nftTokenId;
        uint256 deadline;
        uint256 reservePrice;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    /// STORE VARIABLES
    mapping(uint256 auctionId => Auction) private s_auctions;
    mapping(uint256 auctionId => Bid[]) private s_auctionBids;
    mapping(address bidder => mapping(uint256 auctionId => uint256 amount)) private s_bidderAuctions;
    uint256 private s_auctionId;

    /// EVENTS
    event Deposited(uint256 indexed auctionId, address indexed seller);
    event BidCreated(uint256 indexed auctionId, address indexed bidder, uint256 amount);

    /// MODIFIERS

    /// FUNCTIONS

    // EXTERNAL FUNCTIONS

    /**
     * @notice Deposit an NFT and starts an auction
     * @param nftAddress The address of the NFT contract
     * @param nftTokenId The token id of the NFT
     * @param deadline The deadline of the auction in days
     * @param reservePrice The minium price the bidding price should reach
     * @return auctionId The id of the auction
     */
    function deposit(
        address nftAddress,
        uint256 nftTokenId,
        uint256 deadline,
        uint256 reservePrice
    )
        external
        returns (uint256 auctionId)
    {
        if (nftAddress == address(0)) {
            revert EnglishAuction__AddressCannotBeZero();
        }

        if (block.timestamp + deadline <= block.timestamp) {
            revert EnglishAuction__AuctionDeadlineCannotBeInThePast();
        }

        if (reservePrice == 0) {
            revert EnglishAuction__ReservePriceCannotBeZero();
        }
        auctionId = s_auctionId;
        s_auctions[auctionId] = Auction({
            exists: true,
            seller: msg.sender,
            nftAddress: nftAddress,
            nftTokenId: nftTokenId,
            deadline: block.timestamp + deadline,
            reservePrice: reservePrice
        });
        s_auctionId++;

        ERC721(nftAddress).safeTransferFrom(msg.sender, address(this), nftTokenId);
        emit Deposited(auctionId, msg.sender);
    }

    /**
     * @notice Users can bid on an NFT by depositing ETH. The highest bid wins the auctio
     * @notice The bid is only valid if the reserve price is met
     * @notice The bidder can only bid once
     * @param auctionId The id of the auction
     */
    function bid(uint256 auctionId) external payable {
        if (msg.value == 0) {
            revert EnglishAuction__ReservePriceCannotBeZero();
        }
        Auction storage auction = s_auctions[auctionId];
        if (!auction.exists) {
            revert EnglishAuction__AuctionDoesNotExist();
        }
        if (auction.seller == msg.sender) {
            revert EnglishAuction__SellerCannotBid();
        }

        if (block.timestamp >= auction.deadline) {
            revert EnglishAuction__AuctionHasEnded();
        }

        if (msg.value < auction.reservePrice) {
            revert EnglishAuction__DepositLowerThanReservePrice();
        }

        if (s_bidderAuctions[msg.sender][auctionId] > 0) {
            revert EnglishAuction__BidderHasAlreadyBid();
        }

        s_auctionBids[auctionId].push(Bid({ bidder: msg.sender, amount: msg.value }));
        s_bidderAuctions[msg.sender][auctionId] = msg.value;
        emit BidCreated(auctionId, msg.sender, msg.value);
    }

    /**
     * @notice User can withdraw a bid if the reserve price is not met after the deadline
     * @param auctionId The id of the auction
     */
    function withdraw(uint256 auctionId) external { }

    /**
     * @notice Seller can end the auction if the reserve price is met. The highest bidder gets the NFT transfered to
     * them and the seller gets the ETH of the highest bid
     * @param auctionId The id of the auction
     */
    function sellerEndAuction(uint256 auctionId) external { }

    // EXTERNAL VIEW FUNCTIONS

    function onERC721Received(
        address operator,
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    )
        external
        view
        returns (bytes4)
    {
        if (operator != address(this)) {
            revert EnglishAuction__ReceiverIsNotCurrentContract();
        }
        return this.onERC721Received.selector;
    }

    /**
     * @notice Get the auction details
     * @param auctionId The id of the auction
     * @return auction The auction details
     */
    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return s_auctions[auctionId];
    }

    /**
     * @notice Get the bids of an auction
     * @param auctionId The id of the auction
     * @return bids The bids of the auction
     */
    function getAuctionBids(uint256 auctionId) external view returns (Bid[] memory) {
        return s_auctionBids[auctionId];
    }

    /**
     * @notice Get the amount a bidder has bid on an auction
     * @param auctionId The id of the auction
     * @param bidder The address of the bidder
     */
    function getBidderAmount(uint256 auctionId, address bidder) external view returns (uint256) {
        return s_bidderAuctions[bidder][auctionId];
    }

    /**
     * @notice Get the current auction quantity
     * @return The current auction quantity
     */
    function getAuctionQuantity() external view returns (uint256) {
        return s_auctionId;
    }
}
