// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PodcastDiscovery is Ownable {
    IERC20 public rewardToken;

    struct Podcast {
        string title;
        string description;
        address creator;
        uint episodeCount;
    }

    struct Episode {
        string title;
        uint duration;  // Duration in seconds
        uint rewardPerListen;  // Reward for each listen in token units
        uint adRewardPerListen;  // Additional reward for ad
        bool isPublished;
    }

    mapping(uint => Podcast) public podcasts;
    uint public podcastCount;

    // Separate mapping for episodes
    mapping(uint => mapping(uint => Episode)) public episodes;
    
    mapping(address => uint) public userRewards;

    event PodcastCreated(uint indexed podcastId, string title, address indexed creator);
    event EpisodeAdded(uint indexed podcastId, uint indexed episodeId, string title);
    event RewardClaimed(address indexed user, uint amount);

    // Constructor for PodcastDiscovery that also passes msg.sender as the initial owner to Ownable constructor
    constructor(IERC20 _rewardToken) Ownable(msg.sender) {
    rewardToken = _rewardToken;
}


    // Podcast creation
    function createPodcast(string memory _title, string memory _description) public {
        podcastCount++;
        Podcast storage newPodcast = podcasts[podcastCount];
        newPodcast.title = _title;
        newPodcast.description = _description;
        newPodcast.creator = msg.sender;

        emit PodcastCreated(podcastCount, _title, msg.sender);
    }

    // Adding an episode to the podcast
    function addEpisode(uint _podcastId, string memory _title, uint _duration, uint _rewardPerListen, uint _adRewardPerListen) public {
        require(podcasts[_podcastId].creator == msg.sender, "You are not the creator");
        Podcast storage podcast = podcasts[_podcastId];

        podcast.episodeCount++;
        Episode storage newEpisode = episodes[_podcastId][podcast.episodeCount];
        newEpisode.title = _title;
        newEpisode.duration = _duration;
        newEpisode.rewardPerListen = _rewardPerListen;
        newEpisode.adRewardPerListen = _adRewardPerListen;
        newEpisode.isPublished = true;

        emit EpisodeAdded(_podcastId, podcast.episodeCount, _title);
    }

    // Listen to an episode and reward listeners
    function listenToEpisode(uint _podcastId, uint _episodeId, bool _watchedAd) public {
        require(episodes[_podcastId][_episodeId].isPublished, "Episode not published");

        Episode storage episode = episodes[_podcastId][_episodeId];
        uint reward = episode.rewardPerListen;

        // Additional reward for watching ads
        if (_watchedAd) {
            reward += episode.adRewardPerListen;
        }

        // Reward the listener
        userRewards[msg.sender] += reward;

        emit RewardClaimed(msg.sender, reward);
    }

    // Claim accumulated rewards
    function claimRewards() public {
        uint rewardAmount = userRewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim");

        userRewards[msg.sender] = 0;

        require(rewardToken.transfer(msg.sender, rewardAmount), "Reward transfer failed");
    }
}
