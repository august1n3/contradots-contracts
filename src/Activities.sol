// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMemberRegistry {
    function isClubAdmin(uint256 clubId, address who) external view returns (bool);
    function isClubMember(uint256 clubId, address who) external view returns (bool);
}

interface IRewardToken {
    function mint(address to, uint256 amount) external;
}

interface IBadges {
    function mint(address to, uint256 id, uint256 amount) external;
    function hasBadge(address account, uint256 id) external view returns (bool);
}

/**
 * @title Activities
 * @notice Defines activities controlled by club admins or root.
 * Members submit actions with PoW preimage; contract verifies and rewards.
 */
contract Activities {
    struct Activity {
        uint256 clubId;
        address creator;
        uint256 difficultyTarget;      // hash must be <= target
        uint256 rewardAmount;          // ERC20 tokens to mint per accepted action
        uint256 startBlock;
        uint256 endBlock;              // 0 means no end
        bool    closed;
        uint64  totalActions;
        uint32  maxActionsPerMember;
        uint256 badgeIdOnFirst;        // 0 => no badge
    }

    struct ActionRecord {
        address member;
        bytes32 workHash;
        uint256 nonce;
        uint256 blockAccepted;
        uint256 rewardAmount;
        bool badgeAwarded;
    }

    address public root;
    IMemberRegistry public registry;
    IRewardToken public rewardToken;   // optional (can be unset)
    IBadges public badges;             // optional

    uint256 public nextActivityId;

    mapping(uint256 => Activity) public activities;
    mapping(uint256 => mapping(address => uint32)) public memberActionCount;
    mapping(uint256 => mapping(address => ActionRecord)) public lastAction;

    event ActivityCreated(uint256 indexed activityId, uint256 indexed clubId);
    event ActivityClosed(uint256 indexed activityId);
    event ActionAccepted(
        uint256 indexed activityId,
        address indexed member,
        bytes32 workHash,
        uint256 rewardAmount,
        bool badgeAwarded
    );

    modifier onlyRoot() { require(msg.sender == root, "Not root"); _; }

    constructor(
        address _root,
        address _registry,
        address _rewardToken,   // pass address(0) if no token
        address _badges         // pass address(0) if no badges
    ) {
        root = _root;
        registry = IMemberRegistry(_registry);
        if (_rewardToken != address(0)) {
            rewardToken = IRewardToken(_rewardToken);
        }
        if (_badges != address(0)) {
            badges = IBadges(_badges);
        }
    }

    // --- Activity Management ---

    function createActivity(
        uint256 clubId,
        uint256 difficultyTarget,
        uint256 rewardAmount,
        uint256 startBlock,
        uint256 endBlock,             // 0 means none
        uint32  maxActionsPerMember,
        uint256 badgeIdOnFirst        // 0 means none
    ) external returns (uint256) {
        require(difficultyTarget > 0, "Target zero");
        // Permissions: root or club admin
        bool admin = registry.isClubAdmin(clubId, msg.sender);
        require(admin || msg.sender == root, "Not authorized");
        if (endBlock != 0) {
            require(endBlock > startBlock, "Bad end");
        }
        if (startBlock == 0) {
            startBlock = block.number;
        }

        uint256 id = nextActivityId;
        activities[id] = Activity({
            clubId: clubId,
            creator: msg.sender,
            difficultyTarget: difficultyTarget,
            rewardAmount: rewardAmount,
            startBlock: startBlock,
            endBlock: endBlock,
            closed: false,
            totalActions: 0,
            maxActionsPerMember: maxActionsPerMember,
            badgeIdOnFirst: badgeIdOnFirst
        });
        nextActivityId++;
        emit ActivityCreated(id, clubId);
        return id;
    }

    function closeActivity(uint256 activityId) external {
        Activity storage a = activities[activityId];
        require(a.creator != address(0), "Not found");
        require(!a.closed, "Closed");
        require(msg.sender == a.creator || msg.sender == root, "Not authorized");
        a.closed = true;
        emit ActivityClosed(activityId);
    }

    // --- Action Submission (PoW) ---

    /**
     * @notice Submit an action with payload + nonce to prove work.
     * @param activityId Target activity.
     * @param payload Arbitrary bytes used in preimage (off-chain chosen).
     * @param nonce The mined nonce.
     */
    function submitAction(
        uint256 activityId,
        bytes calldata payload,
        uint256 nonce
    ) external {
        Activity storage a = activities[activityId];
        require(a.creator != address(0), "Activity");
        require(!a.closed, "Closed");
        require(block.number >= a.startBlock, "Not started");
        if (a.endBlock != 0) {
            require(block.number <= a.endBlock, "Expired");
        }
        require(registry.isClubMember(a.clubId, msg.sender), "Not member");

        uint32 count = memberActionCount[activityId][msg.sender];
        require(count < a.maxActionsPerMember, "Limit");

        // Preimage: activityId | member | payload | nonce
        bytes32 workHash = keccak256(
            abi.encodePacked(activityId, msg.sender, payload, nonce)
        );

        // Difficulty check: interpret full 256-bit hash
        // Accept if workHash <= difficultyTarget (target scaled into uint256 space).
        // If difficultyTarget set as uint256 boundary, we compare numeric:
        require(uint256(workHash) <= a.difficultyTarget, "Invalid PoW");

        // Update counters
        memberActionCount[activityId][msg.sender] = count + 1;
        a.totalActions++;

        // Mint reward (if configured)
        uint256 minted = 0;
        if (address(rewardToken) != address(0) && a.rewardAmount > 0) {
            rewardToken.mint(msg.sender, a.rewardAmount);
            minted = a.rewardAmount;
        }

        // Badge on first accepted
        bool badgeAwarded = false;
        if (count == 0 && a.badgeIdOnFirst != 0 && address(badges) != address(0)) {
            // Only mint if user doesn't already have it
            if (!badges.hasBadge(msg.sender, a.badgeIdOnFirst)) {
                badges.mint(msg.sender, a.badgeIdOnFirst, 1);
                badgeAwarded = true;
            }
        }

        lastAction[activityId][msg.sender] = ActionRecord({
            member: msg.sender,
            workHash: workHash,
            nonce: nonce,
            blockAccepted: block.number,
            rewardAmount: minted,
            badgeAwarded: badgeAwarded
        });

        emit ActionAccepted(activityId, msg.sender, workHash, minted, badgeAwarded);
    }

    // --- Views ---

    function getActivity(uint256 activityId) external view returns (Activity memory) {
        return activities[activityId];
    }

    function getLastAction(uint256 activityId, address member) external view returns (ActionRecord memory) {
        return lastAction[activityId][member];
    }

    function remainingActions(uint256 activityId, address member) external view returns (uint32) {
        Activity memory a = activities[activityId];
        if (a.creator == address(0)) return 0;
        uint32 used = memberActionCount[activityId][member];
        if (used >= a.maxActionsPerMember) return 0;
        return a.maxActionsPerMember - used;
    }
}