pragma solidity ^0.4.5;
/**
* 
* Manages mid-game actions for a CypherPoker hand. Most data operations are done on an external PokerHandData contract.
* 
* (C)opyright 2016 to 2017
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
contract PokerHandActions { 
    
    address public owner; //the contract owner -- must exist in any valid PokerHand-type contract    
   
  	function PokerHandActions() {
		owner = msg.sender;
    }
	
	/**
	* Anonymous fallback function.
	*/
	function () {
          throw;
    }
	
	function destroy() {
		selfdestruct(msg.sender);
	}	
	
	/**
     * Records a bet for the sending player in "playerBets", updates the "pot", subtracts the value from their "playerChips" total.
     * The sending player must have agreed, it must be their turn to bet according to the "betPosition" index, the bet value must
     * be less than or equal to the player's available "playerChips" value, and all players must be at a valid betting phase (4, 7, 10, or 13).
     * 
     * Player bets are automatically added to the "pot" and when all players' bets are equal they (bets) are reset to 0 and 
     * their phases are automatically incremented.
     * 
     * @param betValue The bet, in wei, being placed by the player.
     */
	function storeBet (address dataAddr, uint256 betValue) public  {	
		PokerHandData dataStorage = PokerHandData(dataAddr);	
		if (dataStorage.agreed(msg.sender) == false) {
		    throw;
		}
	    if ((dataStorage.allPlayersAtPhase(4) == false) && (dataStorage.allPlayersAtPhase(7) == false) && 
			(dataStorage.allPlayersAtPhase(10) == false) && (dataStorage.allPlayersAtPhase(13) == false)) {			
            throw;
        }
        if (dataStorage.playerChips(msg.sender) < betValue) {			
            throw;
        }
        if (dataStorage.players(dataStorage.betPosition()) != msg.sender) {			
            throw;
        }
        if (dataStorage.players(1) == msg.sender) {
            if (dataStorage.bigBlindHasBet() == false) {
                dataStorage.set_bigBlindHasBet(true);
            } else {
                dataStorage.set_playerHasBet(msg.sender, true);
            }
        } else {
			dataStorage.set_playerHasBet(msg.sender, true);  
        }
        dataStorage.set_playerBets(msg.sender, dataStorage.playerBets(msg.sender) + betValue);
        dataStorage.set_playerChips(msg.sender, dataStorage.playerChips(msg.sender) - betValue);
		dataStorage.set_pot (dataStorage.pot() + betValue);
		dataStorage.set_betPosition((dataStorage.betPosition() + 1) % dataStorage.num_Players());
		uint256 currentBet = dataStorage.playerBets(dataStorage.players(0));
		dataStorage.set_lastActionBlock (block.number);
		for (uint count=1; count<dataStorage.num_Players(); count++) {
		    if (dataStorage.playerBets(dataStorage.players(count)) != currentBet) {
		        //all player bets should match in order to end betting round
		        return;
		    }
		}
		if (allPlayersHaveBet(dataAddr, true) == false) {
		    return;
		}
		//all players have placed at least one bet and bets are equal: reset bets, increment phases, reset bet position and "playerHasBet" flags
		for (count=0; count<dataStorage.num_Players(); count++) {
		    dataStorage.set_playerBets(dataStorage.players(count), 0);
		    dataStorage.set_phase(dataStorage.players(count), dataStorage.phases(dataStorage.players(count))+1);
			dataStorage.set_playerHasBet(dataStorage.players(count), false);
		    dataStorage.set_betPosition(0);
		}
    }
	
	 /**
     * Checks if all players have bet during this round of betting by analyzing the playerHasBet mapping.
     * 
     * @param reset If all players have bet, all playerHasBet entries are set to false if this parameter is true. If false
     * then the values of playerHasBet are not affected.
     * 
     * @return True if all players have bet during this round of betting.
     */
    function allPlayersHaveBet(address dataAddr, bool reset) public constant returns (bool) {
		PokerHandData dataStorage = PokerHandData(dataAddr);
        for (uint count = 0; count < dataStorage.num_Players(); count++) {
            if (dataStorage.playerHasBet(dataStorage.players(count)) == false) {
                return (false);
            }
        }
        if (reset) {
            for (count = 0; count < dataStorage.num_Players(); count++) {
                dataStorage.set_playerHasBet(dataStorage.players(count), false);
            }
        }
        return (true);
    }	 
	 
    /**
     * Records a "fold" action for a player. The player must exist in the "players" array, must have agreed, and must be at a valid
     * betting phase (4,7,10), and it must be their turn to bet according to the "betPosition" index. When fold is correctly invoked
     * any unspent wei in the player's chips are refunded, as opposed to simply abandoning the contract in which case those chips 
     * are not refunded.
     * 
     * Once a player folds correctly they are removed from the "players" array and the betting position is adjusted if necessary. If
     * only one other player remains active in the contract they receive the pot plus their remaining chips while other (folded) players 
     * receive their remaining chips.
     */
    function fold(address dataAddr) public  {	
		PokerHandData dataStorage = PokerHandData(dataAddr);
        if (dataStorage.agreed(msg.sender) == false) {			
		    throw;
		}
		if (dataStorage.lastActionBlock() > 0) {
			if ((dataStorage.allPlayersAtPhase(4) == false) && (dataStorage.allPlayersAtPhase(7) == false) && 
				(dataStorage.allPlayersAtPhase(10) == false) && (dataStorage.allPlayersAtPhase(13) == false)) {            
				throw;
			}
			if (dataStorage.players(dataStorage.betPosition()) != msg.sender) {            
				throw;
			}
		}
        address[] memory newPlayersArray = new address[](dataStorage.num_Players()-1);
        uint pushIndex=0;
        for (uint count=0; count < dataStorage.num_Players(); count++) {
            if (dataStorage.players(count) != msg.sender) {
                newPlayersArray[pushIndex]=dataStorage.players(count);
                pushIndex++;
            }
        }
        if (newPlayersArray.length == 1) {
            //game has ended since only one player's left
            dataStorage.add_winner(newPlayersArray[0]);
            payout(dataAddr);
        } else {
            //game may continue
            dataStorage.new_players(newPlayersArray);
			if (dataStorage.lastActionBlock() > 0) {
				dataStorage.set_betPosition (dataStorage.betPosition() % dataStorage.num_Players()); 
			}
        }
		if (dataStorage.lastActionBlock() > 0) {
			dataStorage.set_lastActionBlock (block.number);
		}
    }
    
    /**
     * Declares the sending player as a winner. Sending player must have agreed to contract and all players must be at be 
     * at phase 14. A winning player may only be declared once at which point all players' phases are updated to 15.
     * 
     * A declared winner may be challenged before timeoutBlocks have elapsed, or later if resolveWinner hasn't yet
     * been called.
     * 
     */
    function declareWinner(address dataAddr, address winnerAddr) public {
		PokerHandData dataStorage = PokerHandData(dataAddr);
        if (dataStorage.agreed(msg.sender) == false) {
		    throw;
		}
	    if (dataStorage.allPlayersAtPhase(14) == false) {
            throw;
        }
		dataStorage.add_declaredWinner(msg.sender, winnerAddr);
        for (uint count=0; count<dataStorage.num_Players(); count++) {
            dataStorage.set_phase(dataStorage.players(count), 15);
        }
		dataStorage.set_lastActionBlock(block.number);
    }
	
	/**
     * Pays out the contract's value by sending the pot + winner's remaining chips to the winner and sending the othe player's remaining chips
     * to them. When all amounts have been paid out, "pot" and all "playerChips" are set to 0 as is the "winner" address. All players'
     * phases are set to 18 and the reset function is invoked.
     * 
     * The "winner" address must be set prior to invoking this call.
     */
    function payout(address dataAddr) private {		
		PokerHandData dataStorage = PokerHandData(dataAddr);
        if (dataStorage.num_winner() == 0) {
            throw;
        }
        for (uint count=0; count<dataStorage.num_winner(); count++) {
            if ((dataStorage.pot() / dataStorage.num_winner()) + dataStorage.playerChips(dataStorage.winner(count)) > 0) {
				if (dataStorage.pay(dataStorage.winner(count), 
					(dataStorage.pot() / dataStorage.num_winner()) 
						+ dataStorage.playerChips(dataStorage.winner(count)))) {                
                    dataStorage.set_pot(0);
					dataStorage.set_playerChips(dataStorage.winner(count), 0);                    
                }
            }
        }
         for (count=0; count < dataStorage.num_Players(); count++) {
            dataStorage.set_phase(dataStorage.players(count), 18);
            if (dataStorage.playerChips(dataStorage.players(count)) > 0) {
				if (dataStorage.pay (dataStorage.players(count), dataStorage.playerChips(dataStorage.players(count)))) {                
                    dataStorage.set_playerChips(dataStorage.players(count), 0);
                }
            }
        }
		dataStorage.set_complete (true);
    }	
}

/**
* 
* Manages data storage for a single CypherPoker hand (round), and provides some publicly-available utility functions.
* 
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
contract PokerHandData { 
    
	struct Card {
        uint index;
        uint suit; 
        uint value;
    }
	
	struct CardGroup {
       Card[] cards;
    }
	
	struct Key {
        uint256 encKey;
        uint256 decKey;
        uint256 prime;
    }
	
    address public owner; //the contract owner -- must exist in any valid Pokerhand-type contract
    address[] public authorizedGameContracts; //the "PokerHand*" contracts exclusively authorized to make changes in this contract's data. This value may only be changed when initReady is ready.
	uint public numAuthorizedContracts; //set when authorizedGameContracts is set
    address[] public players; //players, in order of play, who must agree to contract before game play may begin; the last player is the dealer, player 1 (index 0) is small blind, player 2 (index 2) is the big blind
    uint256 public buyIn; //buy-in value, in wei, required in order to agree to the contract    
    mapping (address => bool) public agreed; //true for all players who agreed to this contract; only players in "players" struct may agree
	uint256 public prime; //shared prime modulus
    uint256 public baseCard; //base or first plaintext card in the deck (all subsequent cards are quadratic residues modulo prime)
    mapping (address => uint256) public playerBets; //stores cumulative bets per betting round (reset before next)    
	mapping (address => uint256) public playerChips; //the players' chips, wallets, or purses on which players draw on to make bets, currently equivalent to the wei value sent to the contract.	
	mapping (address => bool) public playerHasBet; //true if the player has placed a bet during the current active betting round (since bets of 0 are valid)
	bool public bigBlindHasBet; //set to true after initial big blind commitment in order to allow big blind to raise during first round
    uint256 public pot; //total cumulative pot for hand
    uint public betPosition; //current betting player index (in players array)    
    mapping (address => uint256[52]) public encryptedDeck; //incrementally encrypted decks; deck of players[players.length-1] is the final encrypted deck
    mapping (address => uint256[2]) public privateCards; //selected encrypted private/hole cards per player
    struct DecryptPrivateCardsStruct {
        address sourceAddr; //the source player providing the partially decrypted cards
        address targetAddr; //the target player for whom the partially decrypted cards are intended
        uint256[2] cards; //the two partially decrypted private/hole cards
    }
    DecryptPrivateCardsStruct[] public privateDecryptCards; //stores partially decrypted private/hole cards for players
    uint256[5] public publicCards; //selected encrypted public cards
	mapping (address => uint256[5]) public publicDecryptCards; //stores partially decrypted public/community cards
    mapping (address => Key[]) public playerKeys; //players' crypto keypairs 
    //Indexes to the cards comprising the players' best hands. Indexes 0 and 1 are the players' private cards and 2 to 6 are indexes
    //of public cards. All five values are supplied during teh final L1Validate call and must be unique and be in the range 0 to 6 in order to be valid.
    mapping (address => uint[5]) public playerBestHands; 
    mapping (address => Card[]) public playerCards; //final decrypted cards for players (as generated from playerBestHands)
    mapping (address => uint256) public results; //hand ranks per player or numeric score representing actions (1=fold lost, 2=fold win, 3=concede loss, 4=concede win, otherwise hand score)    
    mapping (address => address) public declaredWinner; //address of the self-declared winner of the contract (may be challenged)
    address[] public winner; //address of the hand's/contract's resolved or actual winner(s)
    uint public lastActionBlock; //block number of the last valid player action that was committed. This value is set to the current block on every new valid action.
    uint public timeoutBlocks; //the number of blocks that may elapse before the next valid player's (lack of) action is considered to have timed out 
	uint public initBlock; //the block number on which the "initialize" function was called; used to validate signed transactions
	mapping (address => uint) public nonces; //unique nonces used per contract to ensure that signed transactions aren't re-used
    mapping (address => uint) public validationIndex; //highest successfully completed validation index for each player
    address public challenger; //the address of the current contract challenger / validation initiator    
	bool public complete; //contract is completed.
	bool public initReady; //contract is ready for initialization call (all data reset)
    
    /**
     * Phase values:
     * 0 - Agreement (not all players have agreed to contract yet)contract
     * 1 - Encrypted deck storage (all players have agreed to contract)
     * 2 - Private/hole cards selection
	 * 3 - Interim private cards decryption
     * 4 - Betting
     * 5 - Flop cards selection
     * 6 - Interim flop cards decryption
     * 7 - Betting
     * 8 - Turn card selection
     * 9 - Interim turn card decryption
     * 10 - Betting
     * 11 - River card selection
     * 12 - Interim river card decryption
     * 13 - Betting
     * 14 - Declare winner
     * 15 - Resolution
     * 16 - Level 1 challenge - submit crypto keys
	 * 17 - Level 2 challenge - full contract verification
     * 18 - Payout / hand complete
     * 19 - Mid-game challenge
	 * 20 - Hand complete (unchallenged / signed contract game)
	 * 21 - Contract complete (unchallenged / signed contract game)
     */
    mapping (address => uint8) public phases;

  	function PokerHandData() {  	    
		owner = msg.sender;
		complete = true;
		initReady = true; //ready for initialize
    }
	
	/*
	* Sets the "agreed" flag to true for the transaction sender. Only accounts registered during the "initialize"
	* call are allowed to agree. Once all valid players have agreed the block timeout is started and the next
	* player must commit the next valid action before the timeout has elapsed.
	*
	* The value sent with this function invocation must equal the "buyIn" value (wei) exactly, otherwise
	* an exception is thrown and any included value is refunded. Only when the buy-in value is matched exactly
	* will the "agreed" flag for the player be set and the phase updated to 1.
	*
	* @param nonce A unique nonce to store for the player for this contract. This value must not be re-used until the contract is closed
	* and paid-out in order to prevent re-use of signed transactions.
	*/
	function agreeToContract(uint256 nonce) payable public {
		bool found = false;
        for (uint count=0; count<players.length; count++) {
            if (msg.sender == players[count]) {
                found = true;
            }
        }
        if (found == false) {
			throw;
		}
		if (playerChips[msg.sender] == 0) {
			if (msg.value != buyIn) {
				throw;
			}
			//include additional validation deposit calculations here if desired
			playerChips[msg.sender] = msg.value;
		}
		agreed[msg.sender]=true;
        phases[msg.sender]=1;
		playerBets[msg.sender] = 0;
		playerHasBet[msg.sender] = false;
		validationIndex[msg.sender] = 0;
		nonces[msg.sender] = nonce;
    }
	
	/**
	* Anonymous fallback function.
	*/
	function () {
        throw;		
    }
	
	/**
	* Modifier for functions to allow access only by addresses contained in the "authorizedGameContracts" array.
	*/
	modifier onlyPokerHand {
        uint allowedContractsFound = 0;
        for (uint count=0; count<authorizedGameContracts.length; count++) {
            if (msg.sender == authorizedGameContracts[count]) {
                allowedContractsFound++;
            }
        }
        if (allowedContractsFound == 0) {
             throw;
        }
        _;
    }		
	
	/**
	 * Initializes the data contract.
	 * 
	 * @param primeVal The shared prime modulus on which plaintext card values are based and from which encryption/decryption keys are derived.
	 * @param baseCardVal The value of the base or first card of the plaintext deck. The next 51 ascending quadratic residues modulo primeVal are assumed to
	 * comprise the remainder of the deck (see "getCardIndex" for calculations).
	 * @param buyInVal The exact per-player buy-in value, in wei, that must be sent when agreeing to the contract. Must be greater than 0.
	 * @param timeoutBlocksVal The number of blocks that elapse between the current block and lastActionBlock before the current valid player is
	 * considered to have timed / dropped out if they haven't committed a valid action. A minimum of 2 blocks (roughly 24 seconds), is imposed but
	 * a slightly higher value is highly recommended.	 
	 *
	 */
	function initialize(uint256 primeVal, uint256 baseCardVal, uint256 buyInVal, uint timeoutBlocksVal) public onlyPokerHand {	   	
	    prime = primeVal;
	    baseCard = baseCardVal;
	    buyIn = buyInVal;
	    timeoutBlocks = timeoutBlocksVal;
		initBlock = block.number;
		initReady = false;        
	}	
    
    /**
     * Accesses partially decrypted private/hole cards for a player that has agreed to the contract.
     * 
     * @param sourceAddr The source player that provided the partially decrypted cards for the target.
     * @param targetAddr The target player for whom the partially descrypted cards were intended.
     * @param cardIndex The index of the card (0 or 1) to retrieve. 
     */
    function getPrivateDecryptCard(address sourceAddr, address targetAddr, uint cardIndex) constant public returns (uint256) {
        for (uint8 count=0; count < privateDecryptCards.length; count++) {
            if ((privateDecryptCards[count].sourceAddr == sourceAddr) && (privateDecryptCards[count].targetAddr == targetAddr)) {
                return (privateDecryptCards[count].cards[cardIndex]);
            }
        }
    }

    
    /**
     * Checks if all valild/agreed players are at a specific game phase.
     * 
     * @param phaseNum The phase number that all agreed players should be at.
     * 
     * @return True if all agreed players are at the specified game phase, false otherwise.
     */
    function allPlayersAtPhase(uint phaseNum) public constant returns (bool) {
        for (uint count=0; count < players.length; count++) {
            if (phases[players[count]] != phaseNum) {
                return (false);
            }
        }
        return (true);
    }       
	
	//Public utility functions
    
    function num_Players() public constant returns (uint) {
	     return (players.length);
	 }
	 
	 function num_Keys(address target) public constant returns (uint) {
	     return (playerKeys[target].length);
	 }
	 
	 function num_PlayerCards(address target) public constant returns (uint) {
	     return (playerCards[target].length);
	 }
	 
	 function num_PrivateCards(address targetAddr) public constant returns (uint) {
	     return (DataUtils.arrayLength2(privateCards[targetAddr]));
	 }
	 
	 function num_PublicCards() public constant returns (uint) {
	     return (DataUtils.arrayLength5(publicCards));
	 }	 
	 
	 function num_PrivateDecryptCards(address sourceAddr, address targetAddr) public constant returns (uint) {
        for (uint8 count=0; count < privateDecryptCards.length; count++) {
            if ((privateDecryptCards[count].sourceAddr == sourceAddr) && (privateDecryptCards[count].targetAddr == targetAddr)) {
                return (privateDecryptCards[count].cards.length);
            }
        }
        return (0);
	 }
	 
	 function num_winner() public constant returns (uint) {
	     return (winner.length);
	 }
	 
	 /**
     * Owner / Administrator utility functions.
     */	 
	 function setAuthorizedGameContracts (address[] contractAddresses) public {
		 /*
		 TESTING! -- re-enable when done
	     if ((initReady == false) || (complete == false)) {
	         throw;
	     }
		 */
	     authorizedGameContracts=contractAddresses;
		 numAuthorizedContracts = authorizedGameContracts.length;
	 }
	 
	 /**
	 * Attached PokerHand utility functions.
	 */	
	 
	function add_playerCard(address playerAddress, uint index, uint suit, uint value) public onlyPokerHand{         
        playerCards[playerAddress].push(Card(index, suit, value));
    }
    
    function update_playerCard(address playerAddress, uint cardIndex, uint index, uint suit, uint value) public onlyPokerHand {
        playerCards[playerAddress][cardIndex].index = index;
        playerCards[playerAddress][cardIndex].suit = suit;
        playerCards[playerAddress][cardIndex].value = value;
    }
     
    function set_validationIndex(address playerAddress, uint index) public onlyPokerHand {
		if (index == 0) {
		} else {	
			validationIndex[playerAddress] = index;
		}
    }
	
	function set_result(address playerAddress, uint256 result) public onlyPokerHand {
		if (result == 0) {
			 delete results[playerAddress];
		} else {
			results[playerAddress] = result;
		}
    }
	 
	 function set_complete (bool completeSet) public onlyPokerHand {
		complete = completeSet;
	 }
	 
	 function set_publicCard (uint256 card, uint index) public onlyPokerHand {		
		publicCards[index] = card;
	 }
	 
	 /**
	 * Adds newly encrypted cards for an address or clears out the "encryptedDeck" data for the address. 
	 * Caller must be the same address as "attachedPokerHand".
	 */
	 function set_encryptedDeck (address fromAddr, uint256[] cards) public onlyPokerHand {
	     if (cards.length == 0) {
			 /*
         	for (uint count2=0; count2<52; count2++) {
	        	delete encryptedDeck[fromAddr][count2];
        	}
			*/
        	delete encryptedDeck[fromAddr];
	    } else {
		    for (uint8 count=0; count < cards.length; count++) {
                encryptedDeck[fromAddr][DataUtils.arrayLength52(encryptedDeck[fromAddr])] = cards[count];             
            }
	    }
	 }
	 
	 /**
	 * Adds a private card selection for an address. Caller must be the same address as "attachedPokerHand".
	 */
	 function set_privateCards (address fromAddr, uint256[] cards) public onlyPokerHand {	
		 if (cards.length == 0) {
			for (uint8 count=0; count<2; count++) {				
				delete privateCards[fromAddr][count];
			}
			delete privateCards[fromAddr];
			for (count= 0; count<playerCards[fromAddr].length; count++) {
				delete playerCards[fromAddr][count];
			}
			delete playerCards[fromAddr];
		 } else {
			for (count=0; count<cards.length; count++) {
				privateCards[fromAddr][DataUtils.arrayLength2(privateCards[fromAddr])] = cards[count];             
			} 
		 }
	 }
	 
	 /**
	 * Sets the betting position as an offset within the players array (i.e. current bet position is players[betPosition])
	 */
	 function set_betPosition (uint betPositionVal) public onlyPokerHand {		
        betPosition = betPositionVal;
	 }
	 
	 /**
	 * Sets the bigBlindHasBet flag indicating that at least one complete round of betting has completed.
	 */
	 function set_bigBlindHasBet (bool bigBlindHasBetVal) public onlyPokerHand {
        bigBlindHasBet = bigBlindHasBetVal;
	 }
	 
	 /**
	 * Sets the playerHasBet flag indicating that the player has bet during this round of betting.
	 */
	 function set_playerHasBet (address fromAddr, bool hasBet) public onlyPokerHand {		
        playerHasBet[fromAddr] = hasBet;
	 }
	 
	 /**
	 * Sets the bet value for a player.
	 */
	 function set_playerBets (address fromAddr, uint betVal) public onlyPokerHand {		
        playerBets[fromAddr] = betVal;
	 }
	 
	 /**
	 * Sets the chips value for a player.
	 */
	 function set_playerChips (address forAddr, uint numChips) public onlyPokerHand {		
        playerChips[forAddr] = numChips;
	 }
	 
	 /**
	 * Sets the pot value.
	 */
	 function set_pot (uint potVal) public onlyPokerHand {		
        pot = potVal;
	 }
	 
	 /**
	 * Sets the "agreed" value of a player.
	 */
	 function set_agreed (address fromAddr, bool agreedVal) public onlyPokerHand {		
        agreed[fromAddr] = agreedVal;
	 }
	 
	 /**
	 * Adds a winning player's address to the end of the internal "winner" array.
	 */
	 function add_winner (address winnerAddress) public onlyPokerHand {		
        winner.push(winnerAddress);
	 }
	 
	 /**
	 * Adds winning player's addresses.
	 */
	 function clear_winner () public onlyPokerHand {		
        winner.length=0;
	 }
	 
	 /**
	 * Resets the internal "players" array with the addresses supplied.
	 */
	 function new_players (address[] newPlayers) public onlyPokerHand {
		if (newPlayers.length == 0) {
			for (uint count=0; count<players.length; count++) {
				delete nonces[players[count]];
			}
		}		
        players = newPlayers;
		if (newPlayers.length == 0) {
			initReady=true;
		}
	 }
	 
	 /**
	 * Sets the game phase for a specific address. Caller must be the same address as "attachedPokerHand".
	 */
	 function set_phase (address fromAddr, uint8 phaseNum) public onlyPokerHand {		
        phases[fromAddr] = phaseNum;
	 }
	 
	 /**
	 * Sets the last action block time for this contract. Caller must be the same address as "attachedPokerHand".
	 */
	 function set_lastActionBlock(uint blockNum) public onlyPokerHand {		
		lastActionBlock = blockNum;
	 }
	 
	function set_privateDecryptCards (address fromAddr, uint256[] cards, address targetAddr) public onlyPokerHand {			
		if (cards.length == 0) {
			for (uint8 count=0; count < privateDecryptCards.length; count++) {
				delete privateDecryptCards[count];
			}
		} else {
			uint structIndex = privateDecryptCardsIndex(fromAddr, targetAddr);
			for (count=0; count < cards.length; count++) {
				privateDecryptCards[structIndex].cards[DataUtils.arrayLength2(privateDecryptCards[structIndex].cards)] = cards[count];
			}
		}
	 }
	 
	function set_publicCards (address fromAddr, uint256[] cards) public onlyPokerHand {
		if (cards.length == 0) {
			for (uint8 count = 0; count < 5; count++) {
				publicCards[count]=1;
			}
		} else {
			for (count=0; count < cards.length; count++) {
				publicCards[DataUtils.arrayLength5(publicCards)] = cards[count];
			}
		}
	 }
	 
	 /**
	 * Stores up to 5 partially decrypted public or community cards from a target player. The player must must have agreed to the 
	 * contract, and must be at phase 6, 9, or 12. Multiple invocations may be used to store cards during the multi-card 
	 * phase (6) if desired.
	 * 
	 * In order to correlate decryptions during subsequent rounds cards are stored at matching indexes for players involved.
	 * To illustrate this, in the following example players 1 and 2 decrypted the first three cards and players 2 and 3 decrypted the following
	 * two cards:
	 * 
	 * publicDecryptCards(player 1) = [0x32] [0x22] [0x5A] [ 0x0] [ 0x0] <- partially decrypted only the first three cards
	 * publicDecryptCards(player 2) = [0x75] [0xF5] [0x9B] [0x67] [0xF1] <- partially decrypted all five cards
	 * publicDecryptCards(player 3) = [ 0x0] [ 0x0] [ 0x0] [0x1C] [0x22] <- partially decrypted only the last two cards
	 * 
	 * The number of players involved in the partial decryption of any card at a specific index should be the total number of players minus one
	 * (players.length - 1), since the final decryption results in the fully decrypted card and therefore doesn't need to be stored.
	 *
	 * @param cards The partially decrypted card values to store. Three cards must be stored at phase 6, one card at phase 9, and one card
	 * at phase 12.
	 */
	 function set_publicDecryptCards (address fromAddr, uint256[] cards) public onlyPokerHand {
		if (cards.length == 0) {
			/*
			for (uint count=0; count<5; count++) {				
	            delete publicDecryptCards[fromAddr][count];
	            delete playerBestHands[fromAddr][count];
	        }
			*/
	        delete publicDecryptCards[fromAddr];
			delete playerBestHands[fromAddr];
		} else {			 
			var (maxLength, playersAtMaxLength) = publicDecryptCardsInfo();
			//adjust maxLength value to use as index
			if ((playersAtMaxLength < (players.length - 1)) && (maxLength > 0)) {
				maxLength--;
			}
			for (uint count=0; count < cards.length; count++) {
				publicDecryptCards[fromAddr][maxLength] = cards[count];
				maxLength++;
			}
		}
	 }	 
	 
	 /**
	 * Sets the internal "declaredWinner" address for a sender.
	 */
	 function add_declaredWinner(address fromAddr, address winnerAddr) public onlyPokerHand {
		if (winnerAddr == 0) {
			delete declaredWinner[fromAddr];
		} else {
			declaredWinner[fromAddr] = winnerAddr;
		}
	 }
	 
	 /**
     * Returns the index / position of the privateDecryptCards struct for a specific source and target address
     * combination. If the combination doesn't exist it is created and the index of the new element is
     * returned. Caller must be the same address as "attachedPokerHand".
     * 
     * @param sourceAddr The address of the source or sending player.
     * @param targetAddr The address of the target player to whom the associated partially decrypted cards belong.
     * 
     * @return The index of the element within the privateDecryptCards array that matched the source and target addresses.
     * The element may be new if no matching element can be found.
     */
    function privateDecryptCardsIndex (address sourceAddr, address targetAddr) public onlyPokerHand returns (uint) {      
		for (uint count=0; count < privateDecryptCards.length; count++) {
              if ((privateDecryptCards[count].sourceAddr == sourceAddr) && (privateDecryptCards[count].targetAddr == targetAddr)) {
                  return (count);
              }
         }
         //none found, create a new one
         uint256[2] memory tmp;
         privateDecryptCards.push(DecryptPrivateCardsStruct(sourceAddr, targetAddr, tmp));
         return (privateDecryptCards.length - 1);
    }
	
	function set_playerBestHands(address fromAddr, uint cardIndex, uint256 card) public onlyPokerHand {		
		playerBestHands[fromAddr][cardIndex] = card;
	}
	
	function add_playerKeys(address fromAddr, uint256[] encKeys, uint256[] decKeys) public onlyPokerHand {		
		//caller guarantees that the number of encryption keys matches number decryption keys
		for (uint count=0; count<encKeys.length; count++) {
			playerKeys[fromAddr].push(Key(encKeys[count], decKeys[count], prime));
		}
	}
	
	function remove_playerKeys(address fromAddr) public onlyPokerHand {		
		 delete playerKeys[fromAddr];
	}
	
	function set_challenger(address challengerAddr) public onlyPokerHand {		
		challenger = challengerAddr;
	}
	
	function pay (address toAddr, uint amount) public onlyPokerHand returns (bool) {	
		if (toAddr.send(amount)) {
			return (true);
		} 
		return (false);
	}
		
	
	function publicDecryptCardsInfo() public constant returns (uint maxLength, uint playersAtMaxLength) {
        uint currentLength = 0;
        maxLength = 0;
        for (uint8 count=0; count < players.length; count++) {
            currentLength = DataUtils.arrayLength5(publicDecryptCards[players[count]]);
            if (currentLength > maxLength) {
                maxLength = currentLength;
            }
        }
        playersAtMaxLength = 0;
        for (count=0; count < players.length; count++) {
            currentLength = DataUtils.arrayLength5(publicDecryptCards[players[count]]);
            if (currentLength == maxLength) {
                playersAtMaxLength++;
            }
        }
    }
    
    function length_encryptedDeck(address fromAddr) public constant returns (uint) {
        return (DataUtils.arrayLength52(encryptedDeck[fromAddr]));
    }       	 
    
}

library DataUtils {
	
	/**
     * Returns the number of elements in a non-dynamic, 52-element array. The final element in the array that is
     * greater than 1 is considered the end of the array even if all preceeding elements are less than 2.
     * 
     * @param inputArray The non-dynamic storage array to check for length.
     * 
     */
    function arrayLength52(uint[52] inputArray) internal returns (uint) {
       for (uint count=52; count>0; count--) {
            if ((inputArray[count-1] > 1)) {
                return (count);
            }
        }
        return (0);
    }
    
     /**
     * Returns the number of elements in a non-dynamic, 5-element array. The final element in the array that is
     * greater than 1 is considered the end of the array even if all preceeding elements are less than 2.
     * 
     * @param inputArray The non-dynamic storage array to check for length..
     * 
     */
    function arrayLength5(uint[5] inputArray) internal returns (uint) {
        for (uint count=5; count>0; count--) {
            if ((inputArray[count-1] > 1)) {
                return (count);
            }
        }
        return (0);
    }
    
    /**
     * Returns the number of elements in a non-dynamic, 2-element array. The final element in the array that is
     * greater than 1 is considered the end of the array even if all preceeding elements are less than 2.
     * 
     * @param inputArray The non-dynamic storage array to check for length.
     * 
     */
    function arrayLength2(uint[2] inputArray) internal returns (uint) {
       for (uint count=2; count>0; count--) {
            if ((inputArray[count-1] > 1)) {
                return (count);
            }
        }
        return (0);
    }
}

contract PokerHandValidator {
    modifier isAuthorized {
		PokerHandData handData = PokerHandData(msg.sender);
		bool found = false;
		for (uint count=0; count<handData.numAuthorizedContracts(); count++) {
			if (handData.authorizedGameContracts(count) == msg.sender) {
				found = true;
				break;
			}
		}
		if (!found) {			
             throw;
        }
        _;		
	}
    //include only functions and variables that are accessed
    function challenge (address dataAddr, address challenger) public isAuthorized returns (bool) {}
    function validate (address dataAddr, address msgSender) public isAuthorized returns (bool) {}
}