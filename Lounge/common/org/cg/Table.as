/**
* Implements an IRoom interface as a poker table.
*
* (C)opyright 2014 to 2017
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/

package org.cg {
	
	import feathers.controls.TabBar;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	import org.cg.events.TableEvent;
	import org.cg.interfaces.IRoom;
	import p2p3.interfaces.INetClique;
	import org.cg.TableManager;
	import org.cg.TableMessage;
	import p2p3.events.NetCliqueEvent;
	import p2p3.interfaces.INetCliqueMember;
	import p2p3.interfaces.IPeerMessage;
	import p2p3.netcliques.NetCliqueMember;
	
	public class Table extends EventDispatcher implements IRoom {
		
		private var _clique:INetClique = null; //the clique being used for this table
		private var _manager:TableManager = null; //the parent TableManager instance
		private var _requiredPeers:Array = null; //peers other than local (self) required to be in the room
		private var _numPlayers:uint = 0; //number of players required (if _requiredPeers is set this should be equal to its "length" property)		
		private var _ownerPeerID:String;
		private var _dealerPeerID:String = null;
		private var _smartContractAddress:String = null;
		private var _isOpen:Boolean; //requires password?
		private var _currencyUnits:String;
		private var _buyInAmount:String;
		private var _bigBlindAmount:String;
		private var _smallBlindAmount:String;
		private var _blindsTime:String;
		private var _tableID:String;
		private var _ownTable:Boolean = false; //did local player (self) create the table?
		 //all connected and participating peers/players (more may be connected by they are not active table participants/players); does not include local (self) player
		private var _connectedPeers:Vector.<INetCliqueMember> = new Vector.<INetCliqueMember>();
		//contains information sent from individual players via Table.HELLO messages, including local (self) player
		private var _playersInfo:Vector.<Object> = new Vector.<Object>();
		private var _announceBeaconTimer:Timer; //Timer instance used with automated announce beacon
		public var announceBeaconTime:Number = 5000; //time, in milliseconds, to use to trigger the automated announce beacon
		
		public function createTableInfoObject():Object {
			var tableInfo:Object = new Object();
			tableInfo.tableID = this.tableID;
			tableInfo.ownerPeerID = this.ownerPeerID;
			tableInfo.currentDealerPeerID = this.currentDealerPeerID;
			tableInfo.requiredPeers = this.requiredPeers;
			tableInfo.numPlayers = this.numPlayers;
			tableInfo.isOpen = this.isOpen;
			tableInfo.smartContractAddress = this.smartContractAddress;
			tableInfo.currencyUnits = this.currencyUnits;
			tableInfo.buyInAmount = this.buyInAmount;
			tableInfo.smallBlindAmount = this.smallBlindAmount;
			tableInfo.bigBlindAmount = this.bigBlindAmount;
			tableInfo.blindsTime = this.blindsTime;
			tableInfo.sender = _manager.clique.localPeerInfo.peerID;
			return (tableInfo);
		}
		
		public function Table(manager:TableManager, cliqueRef:INetClique, requiredPeers:Array = null) {
			this._manager = manager;
			this._clique = cliqueRef;
			this._requiredPeers = requiredPeers;			
			this.addListeners();
			super(this);
		}
		
		public function get connected():Boolean {
			if (this.clique == null) {
				return (false);
			}
			return (this.clique.connected);
		}
		
		public function set ownTable(ownSet:Boolean):void {
			this._ownTable = ownSet;
		}
		
		public function get ownTable():Boolean {
			return (this._ownTable);
		}
		
		public function set tableID(IDSet:String):void {
			this._tableID = IDSet;
		}
		
		public function get tableID():String {
			return (this._tableID);
		}
		
		public function set ownerPeerID(ownerIDSet:String):void {
			this._ownerPeerID = ownerIDSet;
		}
		
		public function get ownerPeerID():String {
			return (this._ownerPeerID);
		}
		
		public function get playersInfo():Vector.<Object> {
			return (this._playersInfo);
		}
		
		public function get requiredPeers():Array {
			if (this._requiredPeers == null) {
				this._requiredPeers = new Array();
			}
			return (this._requiredPeers);
		}
		
		public function set isOpen(openSet:Boolean):void {
			this._isOpen = openSet;
		}
		
		public function get isOpen():Boolean {
			return (this._isOpen);
		}
		
		public function set numPlayers(numSet:uint):void {
			if ((this._requiredPeers == null) || (this._requiredPeers["length"] == 0)) {
				this._numPlayers = numSet;
			} else {
				this._numPlayers = this._requiredPeers.length;
			}
		}
		
		public function get numPlayers():uint {
			if ((this._requiredPeers != null) && (this._requiredPeers["length"] != 0)) {
				this._numPlayers = this._requiredPeers.length;
				
			}
			return (this._numPlayers);
		}
		
		public function set currencyUnits(unitsSet:String):void {
			this._currencyUnits = unitsSet;
		}
		
		public function get currencyUnits():String {
			return (this._currencyUnits);
		}
		
		public function set blindsTime(timeSet:String):void {
			this._blindsTime = timeSet;
		}
		
		public function get blindsTime():String {
			return (this._blindsTime);
		}
		
		public function set buyInAmount(amountSet:String):void {
			this._buyInAmount = amountSet;
		}
		
		public function get buyInAmount():String {
			return (this._buyInAmount);
		}
		
		public function set bigBlindAmount(blindSet:String):void {
			this._bigBlindAmount = blindSet;
		}
		
		public function get bigBlindAmount():String {
			return (this._bigBlindAmount);
		}
		
		public function set smallBlindAmount(blindSet:String):void {
			this._smallBlindAmount = blindSet;
		}
		
		public function get smallBlindAmount():String {
			return (this._smallBlindAmount);
		}
			
		public function get currentDealerPeerID():String {
			if (this._dealerPeerID == null) {
				//may also be set through Rochambeau
				this._dealerPeerID = this.ownerPeerID;
			}
			return (this._dealerPeerID);
		}		
		
		public function set currentDealerPeerID(dealerSet:String):void {
			this._dealerPeerID = dealerSet;
		}
		
		public function get dealerIsMe():Boolean {
			if (this.currentDealerPeerID == this.clique.localPeerInfo.peerID) {
				return (true);
			}
			return (false);
		}
		
		public function set smartContractAddress(addressSet:String):void {
			this._smartContractAddress = addressSet;
		}
		
		public function get smartContractAddress():String {
			return (this._smartContractAddress);
		}
		
		public function get connectedPeers():Vector.<INetCliqueMember> {
			return (this._connectedPeers);
		}
		
		/**
		 * Uses the parent TableManager instance to announce the existence of this table.
		 */
		public function announce():void {
			if (this._manager == null) {
				DebugView.addText ("   Can't announce table because parent TableManager instance is null");
				return;
			}
			this._manager.announceTable(this);
		}
		
		
		
		/**
		 * Attempts to join the table by connecting to its segregated clique.
		 * 
		 * @param password An optional password to use to attempt to use to connnect to the table. This parameter may be omitted if 
		 * the table being joined is open.
		 * 
		 * @return The INetClique instance that is will handle the segregrated table communications, or null if the connection attempt couldn't be started.
		 * A returned INetClique implementation should not be assumed to be connected.
		 */
		public function join(password:String = null):INetClique {
			DebugView.addText ("Table.join");
			if (this._clique == null) {
				var options:Object = new Object();
				options.groupName = this.tableID;
				if (password != null) {
					options.password = password;
				}
				this._clique = this._manager.clique.newRoom(options);
				this.addListeners();
			}		
			return (this._clique);
		}
		
		public function leave():void {			
			this.destroy();
		}
		
		/**
		 * Event listener invoked when the table instance has successfully connected to its segregated clique.
		 * 
		 * @param	eventObj A NetCliqueEvent object.
		 */
		private function onCliqueConnect(eventObj:NetCliqueEvent):void {			
			DebugView.addText("onCliqueConnect");
			this.sendHelloMessage();
			var newPlayerObj:Object = new Object();
			newPlayerObj.peerInfo = this._manager.clique.localPeerInfo;
			newPlayerObj.peerID = this._manager.clique.localPeerInfo.peerID;
			newPlayerObj.handle = this._manager.profile.profileHandle;
			if (this._manager.lounge.ethereum != null) {
				newPlayerObj.ethereumAccount = this._manager.lounge.ethereum.account;
			} else {
				newPlayerObj.ethereumAccount = "0x";
			}
			newPlayerObj.iconBA = this._manager.profile.newIconByteArray;
			newPlayerObj.iconBMD = this._manager.profile.iconData;			
			this._playersInfo.push(newPlayerObj);
		}
		
		/**
		 * Returns true if quorum has been achieved. Quorum has been achieved when all allowed or required players have connected
		 * and successfully exchanged Table.HELLO messages. Disallowed player connections are not counted toward the quorum.
		 */
		public function get quorumAchieved():Boolean {		
			//note that connectedPeers.length should always be one less than _playersInfo.length
			if (this._playersInfo.length == this.numPlayers) {
				return (true);
			}
			return (false);
		}
		
		/**
		 * Returns an info object for a peer that was allowed to connect, and has connected to, this table.
		 * 
		 * @param	peerID The peer ID for which to retrieve an info object.
		 * 
		 * @return An info object containing the player's "peerInfo" (INetCliqueMember instance), "peerID" (String), "handle" (String),
		 * "iconBA" (ByteArray containing raw ARGB graphics data for the player's icon), and "iconBMD" (BitmapData object containing the player's
		 * icon graphic).
		 */
		public function getInfoForPeer(peerID:String):Object {
			for (var count:int = 0; count < this._playersInfo.length; count++) {				
				if (this._playersInfo[count].peerID == peerID) {
					return (this._playersInfo[count]);
				}
			}
			return (null);
		}
		
		/**
		 * Enables periodic table announcements for this instance.
		 */
		public function enableAnnounceBeacon():void {
			this.disableAnnounceBeacon();
			this._announceBeaconTimer = new Timer(announceBeaconTime);
			this._announceBeaconTimer.addEventListener (TimerEvent.TIMER, this.onAnnounceTimer);
			this._announceBeaconTimer.start();
		}
		
		public function onAnnounceTimer(eventObj:TimerEvent):void {
			this._manager.announceTable(this);
		}
		
		/**
		 * Disables periodic table announcements for this instance.
		 */
		public function disableAnnounceBeacon():void {
			if (this._announceBeaconTimer != null) {
				this._announceBeaconTimer.stop();
				this._announceBeaconTimer.removeEventListener(TimerEvent.TIMER, this.onAnnounceTimer);
				this._announceBeaconTimer = null;
			}
		}
		
		/**
		 * Add the peer to the list of the table's registered/connected peers (_connectedPeers) if they are allowed to be added.		 
		 * 
		 * @param	peerID The peer ID of the peer to attempt to add to the table.
		 * 
		 * @return True if the peer was successfully added, false if they were not allowed or have already been added.
		 */
		private function addPeerToTable(peerID:String):Boolean {
			for (var count:int = 0; count < this._connectedPeers.length; count++) {
				if (this._connectedPeers[count].peerID == peerID) {
					return (false);
				}
			}
			if (this._requiredPeers == null){								
				var member:INetCliqueMember = new NetCliqueMember(peerID);
				this._connectedPeers.push(member);
				return (true);
			} else if (this._requiredPeers.length == 0){
				member = new NetCliqueMember(peerID);
				this._connectedPeers.push(member);				
				return (true);
			} else {				
				for (count = 0; count < this._requiredPeers.length; count++) {
					if (peerID == this._requiredPeers[count]) {
						member = new NetCliqueMember(peerID);
						this._connectedPeers.push(member);
						return (true);
						break;
					}	
				}
			}
			return (false);
		}
		
		/**
		 * Verifies that an incoming message was sent from an allowed peer. An allowed peer is one that appears
		 * in the connectedPeers array.
		 * 
		 * @param	peerID The peer ID to check.
		 * 
		 * @return True if the sender is allowed to communicate in this table, false otherwise.
		 */
		private function peerMayCommunicate(peerID:String):Boolean {			
			for (var count:int = 0; count < this.connectedPeers.length; count++) {
				if (peerID == this.connectedPeers[count].peerID) {
					return (true);
				}
			}
			return (false);
		}
		
		private function onPeerMessage(eventObj:NetCliqueEvent):void {
			if (!peerMayCommunicate(eventObj.message.getSourcePeerIDList()[0].peerID)) {
				DebugView.addText ("Peer " + eventObj.message.getSourcePeerIDList()[0].peerID + " is not allowed to communicate at this table.");
				return;
			}
			var peerMsg:TableMessage = TableMessage.validateTableMessage(eventObj.message);						
			if (peerMsg == null) {					
				//not a table manager message
				return;
			}			
			if (eventObj.message.hasSourcePeerID(this.clique.localPeerInfo.peerID)) {
				//already processed by us				
				return;
			}		
			if (eventObj.message.hasTargetPeerID(this.clique.localPeerInfo.peerID)) {
				//message is either specifically for us or for everyone ("*")
				this.processPeerMessage(peerMsg);
			} else {
				//message not intended for us
			}
		}
		
		private function sendHelloMessage():void {			
			var msg:TableMessage = new TableMessage();
			var payload:Object = new Object();
			//Get this information from config
			payload.peerID = this.clique.localPeerInfo.peerID; 
			payload.handle = this._manager.profile.profileHandle;
			payload.icon = this._manager.profile.newIconByteArray;
			if (this._manager.lounge.ethereum != null) {
				payload.ethereumAccount = this._manager.lounge.ethereum.account;
			} else {
				payload.ethereumAccount = "0x";
			}
			msg.createTableMessage(TableMessage.HELLO, payload);
			msg.targetPeerIDs = "*";
			this.clique.broadcast(msg);
		}
		
		private function processPeerMessage(peerMsg:TableMessage):void {
			try {
				switch (peerMsg.tableMessageType) {					
					case TableMessage.HELLO:						
						DebugView.addText ("   TableMessage.HELLO");
						DebugView.addText ("      From: " + peerMsg.sourcePeerIDs);
						DebugView.addText ("      Player handle: " + peerMsg.data.handle);						
						this.addNewPlayerInfo(peerMsg);						
						break;
					default: 
						DebugView.addText("   Unrecognized peer message:");
						DebugView.addText(peerMsg);
						break;
				}
			} catch (err:*) {
				//something went wrong processing the message
				DebugView.addText (err.getStackTrace());
			}
		}
		
		private function addNewPlayerInfo(peerMsg:TableMessage):void {
			DebugView.addText("addNewPlayerInfo");			
			for (var count:int = 0; count < this._playersInfo.length; count++) {
				DebugView.addText ("   Already added:" + this._playersInfo[count].peerID );
				DebugView.addText("   Sender:" +peerMsg.getSourcePeerIDList()[0].peerID);
				if (this._playersInfo[count].peerID == peerMsg.getSourcePeerIDList()[0].peerID) {
					//only add once!
					return;
				}
			}
			DebugView.addText("...adding");
			var newPlayerObj:Object = new Object();
			newPlayerObj.peerInfo = peerMsg.getSourcePeerIDList()[0];
			newPlayerObj.peerID = peerMsg.getSourcePeerIDList()[0].peerID;
			newPlayerObj.handle = peerMsg.data.handle;
			newPlayerObj.ethereumAccount = peerMsg.data.ethereumAccount;
			newPlayerObj.iconBA = peerMsg.data.icon;
			newPlayerObj.iconBMD = new BitmapData(64, 64);
			var bounds:Rectangle = new Rectangle(0, 0, 64, 64);
			BitmapData(newPlayerObj.iconBMD).setPixels(bounds, newPlayerObj.iconBA);
			this._playersInfo.push(newPlayerObj);
			if (this.quorumAchieved) {							
				var event:TableEvent = new TableEvent(TableEvent.QUORUM);
				this.dispatchEvent(event);
			}
		}		
		
		private function onPeerConnect(eventObj:NetCliqueEvent):void {
			DebugView.addText ("onPeerConnect: " + eventObj.memberInfo.peerID);
			if (this.quorumAchieved) {
				//don't register any additional connections
				return;
			}
			this.addPeerToTable(eventObj.memberInfo.peerID);
			this.sendHelloMessage();			
		}
		
		private function onCliqueDisconnect(eventObj:NetCliqueEvent):void {
			//we may want to attempt re-connecting so don't clean up the clique
			var event:TableEvent = new TableEvent(TableEvent.LEFT);
			this.dispatchEvent(event);
		}
		
		private function onPeerDisconnect(eventObj:NetCliqueEvent):void {
			var leavingPeerID:String = eventObj.memberInfo.peerID;
			for (var count:int = 0; count < this._playersInfo.length; count++) {
				if (this._playersInfo[count].peerID == leavingPeerID) {
					this._playersInfo.splice(count, 1);
					break;
				}
			}
			for (count = 0; count < this._connectedPeers.length; count++) {
				if (this._connectedPeers[count].peerID == leavingPeerID) {
					this._connectedPeers.splice(count, 1);
					var event:TableEvent = new TableEvent(TableEvent.PLAYER_LEAVE);
					event.memberInfo = eventObj.memberInfo;					
					this.dispatchEvent(event);					
					return;
				}
			}		
		}
		
		private function addListeners():void {
			this.removeListeners();
			if (this._clique == null) {
				return;
			}				
			this._clique.addEventListener(NetCliqueEvent.CLIQUE_CONNECT, this.onCliqueConnect);			
			this._clique.addEventListener(NetCliqueEvent.PEER_CONNECT, this.onPeerConnect);
			this._clique.addEventListener(NetCliqueEvent.CLIQUE_DISCONNECT, this.onCliqueDisconnect);
			this._clique.addEventListener(NetCliqueEvent.PEER_DISCONNECT, this.onPeerDisconnect);
			this._clique.addEventListener(NetCliqueEvent.PEER_MSG, this.onPeerMessage);
		}
		
		private function removeListeners():void {
			if (this._clique == null) {
				return;
			}
			this._clique.removeEventListener(NetCliqueEvent.CLIQUE_CONNECT, this.onCliqueConnect);			
			this._clique.removeEventListener(NetCliqueEvent.PEER_CONNECT, this.onPeerConnect);
			this._clique.removeEventListener(NetCliqueEvent.CLIQUE_DISCONNECT, this.onCliqueDisconnect);
			this._clique.removeEventListener(NetCliqueEvent.PEER_DISCONNECT, this.onPeerDisconnect);
			this._clique.removeEventListener(NetCliqueEvent.PEER_MSG, this.onPeerMessage);
		}
		
		
		public function get clique():INetClique {
			return (this._clique);
		}
		
		/**
		 * Destroy the instance by disconnecting and cleaning up the clique, clearing all data and references.
		 */
		public function destroy():void {
			var event:TableEvent = new TableEvent(TableEvent.DESTROY);
			this.dispatchEvent(event);
			this._clique.disconnect();			
			this.removeListeners();			
			this._clique = null;
			this._requiredPeers = null;
		}
	}
}