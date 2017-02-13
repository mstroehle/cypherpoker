/**
* Manages table information and interactions such as joining and creation of new tables.
*
* (C)opyright 2014 to 2017
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/

//TODO: Create contract management widget and move related functionality from here to there

package org.cg.widgets {
	
	import events.EthereumWeb3ClientEvent;
	import feathers.controls.Label;
	import feathers.controls.Button;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import org.cg.GlobalSettings;
	import feathers.data.ListCollection;
	import org.cg.StarlingViewManager;
	import flash.geom.Point;
	import feathers.controls.Radio;
	import feathers.core.ToggleGroup;
	import org.cg.Table;
	import org.cg.events.EthereumEvent;
	import org.cg.interfaces.IWidget;
	import starling.events.Event;
	import org.cg.events.TableManagerEvent;
	import feathers.controls.renderers.IListItemRenderer;
	import org.cg.widgets.GameListItemRenderer;
	import org.cg.events.TableEvent;
	import org.cg.widgets.Widget;
	import starling.display.Sprite;
	import feathers.controls.Alert;
	import org.cg.interfaces.IRoom;
	import org.cg.Lounge;
	import org.cg.events.LoungeEvent;
	import feathers.controls.List;
	import net.kawa.tween.KTween;
	import net.kawa.tween.easing.Quad;
	import feathers.controls.ToggleButton;
	import feathers.controls.ImageLoader;
	import org.cg.DebugView;
		
	public class TableManagerWidget extends Widget implements IWidget {
		
		public var tableList:List;
		//Fields used for reviewing information in the currently selected list item
		public var listDetailPrompt_tableID:Label;
		public var listDetail_tableID:Label;
		public var listDetailPrompt_ownerPeerID:Label;
		public var listDetail_ownerPeerID:Label;
		public var listDetailPrompt_buyInAmount:Label;
		public var listDetail_buyInAmount:Label;
		public var listDetailPrompt_smallBlindAmount:Label;
		public var listDetail_smallBlindAmount:Label;
		public var listDetailPrompt_bigBlindAmount:Label;
		public var listDetail_bigBlindAmount:Label;
		public var listDetailPrompt_blindsTime:Label;
		public var listDetail_blindsTime:Label;
		public var listDetailPrompt_handContractAddress:Label;
		public var listDetail_handContractAddress:Label;
		public var listDetail_playersIcon:ImageLoader;
		public var listDetail_openTableIcon:ImageLoader;
		public var listDetail_closedTableIcon:ImageLoader;
		public var listDetail_requiredPlayers:List;
		public var joinTableButton:Button;
		public var cancelButton:Button;
		public var startCreateTableButton:Button; //button used to open the user interface for creating a new table
		//UI elements used when creating a new table
		public var create_createTableButton:Button; //button used to create a new table
		public var create_cancelButton:Button;
		public var create_contractGameRadio:Radio;
		public var create_funGameRadio:Radio;
		public var create_createTableIDInput:TextInput;
		public var create_newTableIDButton:Button;		
		public var create_numPlayersPrompt:Label;
		public var create_numPlayersList:PickerList;
		public var create_tableTypeToggle:ToggleSwitch;
		public var create_tablePasswordInput:TextInput;
		public var create_requiredPlayerInput:TextInput;
		public var create_addRequiredPlayerButton:Button;
		public var create_removeRequiredPlayerButton:Button;
		public var create_requiredPlayersList:List;	
		public var create_addRequiredPlayerArrow:ImageLoader;
		public var create_requiredPlayersPrompt:Label;
		public var create_tableIDPrompt:Label;
		public var create_tableTypePrompt:Label;
		public var create_smartContractPrompt:Label;
		public var create_contractsList:PickerList;		
		public var create_manageContractsButton:Button;
		public var create_buyInAmountPrompt:Label;
		public var create_buyInAmount:TextInput;
		public var create_denominationPicker:PickerList;
		public var create_bigBlindAmountPrompt:Label;
		public var create_bigBlindAmount:TextInput;
		public var create_smallBlindAmountPrompt:Label;
		public var create_smallBlindAmount:TextInput;
		public var createRequiredPlayerListEmptyPrompt:String = "Any player may join";
		private var _tableListOrigin:Point;
		private var _startCreateTableButtonOrigin:Point = null;
		private var _listDetailViewItems:Array = null;
		private var _listDetailItemsOrgs:Vector.<Object> = new Vector.<Object>();
		private var _createViewItems:Array = null;
		private var _createItemsOrgs:Vector.<Object> = new Vector.<Object>();
		private var _gameTypeRadioGroup:ToggleGroup;
		private var _currentDenomination:String;
		private var _currentSelectedGameListItem:IListItemRenderer = null;
		private var _currentSelectedGameListItemData:Object = null;
		
		public function TableManagerWidget(loungeRef:Lounge, container:*, widgetData:XML) {
			DebugView.addText("GameSelectorWidget created");
			super(loungeRef, container, widgetData);
		}
		
		private function onNewTableReceived(eventObj:TableManagerEvent):void {
			DebugView.addText ("TableManagerWidget.onNewTableReceived");
			var tableInfoObj:Object = new Object();
			tableInfoObj.tableID = eventObj.table.tableID;
			tableInfoObj.ownerPeerID = eventObj.table.ownerPeerID;
			tableInfoObj.buyInAmount = formatToCurrency(eventObj.table.buyInAmount, eventObj.table.currencyUnits, "ether");
			if (eventObj.table.isOpen) {
				tableInfoObj.tableType = "open";
			} else {
				tableInfoObj.tableType = "closed";
			}
			tableInfoObj.numPlayers = eventObj.table.numPlayers;
			tableInfoObj.bigBlindAmount = formatToCurrency(eventObj.table.bigBlindAmount, eventObj.table.currencyUnits, "ether");
			tableInfoObj.smallBlindAmount = formatToCurrency(eventObj.table.smallBlindAmount, eventObj.table.currencyUnits, "ether");
			tableInfoObj.blindsTime = eventObj.table.blindsTime;
			tableInfoObj.requiredPlayers = eventObj.table.requiredPeers.join(";");
			tableInfoObj.handContractAddress = eventObj.table.smartContractAddress;
			tableInfoObj.table = eventObj.table;
			this.tableList.dataProvider.addItem(tableInfoObj);
		}
		
		private function onNewTableCreated(eventObj:TableManagerEvent):void {
			DebugView.addText ("TableManagerWidget.onNewTableCreated");
			var tableInfoObj:Object = new Object();
			tableInfoObj.tableID = eventObj.table.tableID;
			tableInfoObj.ownerPeerID = eventObj.table.ownerPeerID;
			tableInfoObj.buyInAmount = formatToCurrency(eventObj.table.buyInAmount, eventObj.table.currencyUnits, "ether");
			if (eventObj.table.isOpen) {
				tableInfoObj.tableType = "open";
			} else {
				tableInfoObj.tableType = "closed";
			}
			tableInfoObj.numPlayers = eventObj.table.numPlayers;
			tableInfoObj.bigBlindAmount = formatToCurrency(eventObj.table.bigBlindAmount, eventObj.table.currencyUnits, "ether");
			tableInfoObj.smallBlindAmount = formatToCurrency(eventObj.table.smallBlindAmount, eventObj.table.currencyUnits, "ether");
			tableInfoObj.blindsTime = eventObj.table.blindsTime;
			tableInfoObj.requiredPlayers = eventObj.table.requiredPeers.join(";");
			tableInfoObj.handContractAddress = eventObj.table.smartContractAddress;
			tableInfoObj.table = eventObj.table;
			this.tableList.dataProvider.addItem(tableInfoObj);
			DebugView.addText ("   Announcing new table...");
			tableInfoObj.table.announce();
			lounge.tableManager.enableTableBeacons();
		}
		
		private function formatToCurrency(inputValue:String, inputDenom:String, outputDenom:String):String {
			if (lounge.ethereum != null) {
				var weiAmount:String = lounge.ethereum.web3.toWei (inputValue, inputDenom);
				var output:String = lounge.ethereum.web3.fromWei(weiAmount, outputDenom);
				if (outputDenom == "ether") {
					output = "Ξ" +output;
				}
				return (output);
			}
			return (inputValue);
		}
		
		private function hideTableListDetails():void {
			for (var count:int = 0; count < this._listDetailItemsOrgs.length; count++) {
				var originObj:Object = this._listDetailItemsOrgs[count];
				if ((this._listDetailItemsOrgs[count]["tween"] != null) && (this._listDetailItemsOrgs[count]["tween"] != undefined)) {
					this._listDetailItemsOrgs[count].tween.cancel();
				}
				this._listDetailItemsOrgs[count].tween = KTween.to(this._listDetailItemsOrgs[count].target, 0.5, {x:this.tableList.x, alpha:0}, Quad.easeInOut);
			}			
		}
		
		private function hideCreateTable(eventObj:Event = null):void {
			DebugView.addText ("hideCreateTable");
			for (var count:int = 0; count < this._createItemsOrgs.length; count++) {
				var originObj:Object = this._createItemsOrgs[count];
				if ((this._createItemsOrgs[count]["tween"] != null) && (this._createItemsOrgs[count]["tween"] != undefined)) {
					this._createItemsOrgs[count].tween.cancel();
				}
				this._createItemsOrgs[count].tween = KTween.to(this._createItemsOrgs[count].target, 0.5, {x:this.tableList.x, alpha:0}, Quad.easeInOut, this.onHideCreateTable);
			}
			if (eventObj != null) {
				this.showStartCreateTableButton();
				this.showTableList();			
			}
		}
		
		private function onHideCreateTable():void {
			for (var count:int = 0; count < this._createItemsOrgs.length; count++) {
				this._createItemsOrgs[count].target.visible = false;
			}
		}
		
		private function onNoConnectionAlertClose(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.CLOSE, this.onNoConnectionAlertClose);
			if (eventObj.data.startConnection) {
				DebugView.addText ("Connection should be started.");
				try {
					var connectivityWidget:IWidget = this.getInstanceByClass("org.cg.widgets.ConnectivitySelectorWidget")[0];
					connectivityWidget.activate(true);
				} catch (err:*) {
					DebugView.addText ("   Couldn't find registered widget instance from class  \"org.cg.widgets.ConnectivitySelectorWidget\"");
				}
			} else {
				DebugView.addText ("No connection.");
			}
		}
		
		private function onManageSmartContractsClick(eventObj:Event):void {			
			var alert:Alert = StarlingViewManager.alert("This action will cancel table creation and take you to the smart contract manager. Do you wish to continue?", "Open smart contract manager?", 
						new ListCollection([{label:"YES", openSCManager:true}, {label:"NO", openSCManager:false}]), null, true, true);
			alert.addEventListener(Event.CLOSE, this.onConfirmManageSmartContracts);
		}
		
		private function onConfirmManageSmartContracts(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.CLOSE, this.onConfirmManageSmartContracts);
			if (eventObj.data.openSCManager) { 
				try {
					var SCManagerWidget:IWidget = this.getInstanceByClass("org.cg.widgets.SmartContractManagerWidget")[0];
					SCManagerWidget.activate(true);
					this.hideCreateTable();
					this.showStartCreateTableButton();
					this.showTableList();
				} catch (err:*) {
					DebugView.addText ("   Couldn't find registered widget instance from class  \"org.cg.widgets.SmartContractManagerWidget\"");
				}
			}
		}
		
		private function showCreateTable(eventObj:Event = null):void {
			if (lounge.tableManager == null) {
				var alert:Alert = StarlingViewManager.alert("A new connection must be started before a table can be created.\nStart connection now?", "No Connection Available", new ListCollection([{label:"YES", startConnection:true}, {label:"NO", startConnection:false}]), null, true, true);
				alert.addEventListener(Event.CLOSE, this.onNoConnectionAlertClose);
				return;
			}
			this.populateCreateContractsList();
			this.create_tablePasswordInput.text = " "; //force align icon
			this.create_tablePasswordInput.text = "";
			this.create_tablePasswordInput.invalidate();
			this.create_tableTypeToggle.isSelected = false;
			for (var count:int = 0; count < this._createItemsOrgs.length; count++) {
				var originObj:Object = this._createItemsOrgs[count];
				if ((this._createItemsOrgs[count]["tween"] != null) && (this._createItemsOrgs[count]["tween"] != undefined)) {
					this._createItemsOrgs[count].tween.cancel();
				}
				var targetPos:Object = new Object();
				targetPos.x = this._createItemsOrgs[count].x;
				targetPos.y = this._createItemsOrgs[count].y;
				this._createItemsOrgs[count].target.visible = true;
				targetPos.alpha = 1;
				this._createItemsOrgs[count].tween = KTween.to(this._createItemsOrgs[count].target, 0.5, targetPos, Quad.easeInOut);
			}
			this.create_createTableIDInput.text = lounge.tableManager.generateTableID();
			this.hideStartCreateTableButton();
			this.hideTableList();
		}
		
		private function hideTableList():void {
			this.tableList.isEnabled = false;
			KTween.to (this.tableList, 0.3, {x:(this.tableList.width *-1), alpha:0}, Quad.easeInOut, function():void {tableList.visible = false; });
		}
		
		private function showTableList():void {
			this.tableList.visible = true;
			KTween.to (this.tableList, 0.3, {x:this._tableListOrigin.x, y:this._tableListOrigin.y, alpha:1}, Quad.easeInOut);
			this.tableList.isEnabled = true;
		}
		
		private function showTableListDetails():void {
			for (var count:int = 0; count < this._listDetailItemsOrgs.length; count++) {
				var originObj:Object = this._listDetailItemsOrgs[count];
				if ((this._listDetailItemsOrgs[count]["tween"] != null) && (this._listDetailItemsOrgs[count]["tween"] != undefined)) {
					this._listDetailItemsOrgs[count].tween.cancel();
				}
				var targetPos:Object = new Object();
				targetPos.x = this._listDetailItemsOrgs[count].x;
				targetPos.y = this._listDetailItemsOrgs[count].y;
				targetPos.alpha = 1;
				this._listDetailItemsOrgs[count].tween = KTween.to(this._listDetailItemsOrgs[count].target, 0.5, targetPos, Quad.easeInOut);
			}
			this.hideStartCreateTableButton();
		}
		
		private function hideStartCreateTableButton():void {
			KTween.to(this.startCreateTableButton, 0.3, { y:(this.startCreateTableButton.height * -1)}, Quad.easeInOut, function():void {startCreateTableButton.visible = false;});
		}
		
		private function showStartCreateTableButton():void {
			this.startCreateTableButton.visible = true;
			KTween.to(this.startCreateTableButton, 0.3, {x:this._startCreateTableButtonOrigin.x, y:this._startCreateTableButtonOrigin.y}, Quad.easeInOut);
		}
		
		private function onListItemSelect(selectedData:Object, selectedItem:IListItemRenderer):void {			
			this._currentSelectedGameListItemData = selectedData;
			this._currentSelectedGameListItem = selectedItem;
			this.listDetail_tableID.text = selectedData.tableID;
			this.listDetail_ownerPeerID.text = selectedData.ownerPeerID;
			this.listDetail_buyInAmount.text = selectedData.buyInAmount;
			this.listDetail_smallBlindAmount.text = selectedData.smallBlindAmount;
			this.listDetail_bigBlindAmount.text = selectedData.bigBlindAmount;
			this.listDetail_blindsTime.text = selectedData.blindsTime;
			this.listDetail_handContractAddress.text = selectedData.handContractAddress;
			if (selectedData.tableType == "closed") {
				this.listDetail_openTableIcon.visible = false;
				this.listDetail_closedTableIcon.visible = true;
			} else {
				this.listDetail_openTableIcon.visible = true;
				this.listDetail_closedTableIcon.visible = false;
			}
			if (this.listDetail_requiredPlayers.dataProvider == null) {
				this.listDetail_requiredPlayers.dataProvider = new ListCollection();
			}
			this.listDetail_requiredPlayers.dataProvider.removeAll();
			if ((selectedData["requiredPlayers"] != null) && (selectedData["requiredPlayers"] != undefined) && (selectedData["requiredPlayers"] != "")) {
				var playersSplit:Array = selectedData.requiredPlayers.split(";");
				for (var count:int = 0; count < playersSplit.length; count++) {
					this.listDetail_requiredPlayers.dataProvider.addItem({label:String(count+1)+": "+playersSplit[count]});
				}
			} else {
				if (this.listDetail_openTableIcon.visible) {
					this.listDetail_requiredPlayers.dataProvider.addItem({label: String(selectedData.numPlayers)+" players required."});
					this.listDetail_requiredPlayers.dataProvider.addItem({label: "Open table - anyone may join."});
				} else {
					this.listDetail_requiredPlayers.dataProvider.addItem({label: String(selectedData.numPlayers)+" players required."});
					this.listDetail_requiredPlayers.dataProvider.addItem({label: "Closed table - password needed."});
				}
			}
			if (this._currentSelectedGameListItemData.table.connected) {
				this.joinTableButton.isEnabled = false;
			} else {
				this.joinTableButton.isEnabled = true;
			}
			this.showTableListDetails();
		}
		
		private function onCancelClick(eventObj:Event):void {
			DebugView.addText ("onCancelClick");
			this._currentSelectedGameListItem = null;
			this._currentSelectedGameListItemData = null;
			this.hideTableListDetails();
			this.showTableList();
			this.showStartCreateTableButton();
		}
		
		private function onCreateGameTypeUpdate(eventObj:Event):void {
			if (this._gameTypeRadioGroup.selectedItem == this.create_funGameRadio) {
				//for-fun game
				this.create_contractsList.isEnabled = false;
				this.create_manageContractsButton.isEnabled = false;
			} else {
				//contract game
				this.create_contractsList.isEnabled = true;
				this.create_manageContractsButton.isEnabled = true;
			}
		}
		
		private function generateNewGameID(eventObj:Event):void {
			DebugView.addText ("TableManagerWidget.generateNewGameID");
			if (lounge.tableManager == null) {
				DebugView.addText ("   TableManager instance not registered with Lounge. Can't continue!");
			}
			this.create_createTableIDInput.text = lounge.tableManager.generateTableID();
			DebugView.addText ("   Generated new table ID: "+this.create_createTableIDInput.text);
		}
		
		private function onToggleCreatePassword(eventObj:Event):void {
			this.create_tablePasswordInput.text = "";
			if (this.create_tableTypeToggle.isSelected) {
				this.create_tablePasswordInput.isEnabled = true;
				this.create_tablePasswordInput.prompt = "Enter closed table password";
			} else {
				this.create_tablePasswordInput.isEnabled = false;
				this.create_tablePasswordInput.prompt = "Table is open - no password needed to join";
			}
		}
		
		private function onCreateAddPlayer(eventObj:Event):void {
			if (this.create_requiredPlayerInput.text != "") {
				if (this.create_requiredPlayerInput.text == lounge.clique.localPeerInfo.peerID) {
					var alert:Alert=StarlingViewManager.alert("Own peer ID is automatically included; only add other players' IDs.", "Can't add required player", new ListCollection([{label:"OKAY"}]), null, true, true);
					return;
				}
				if (this.create_requiredPlayersList.dataProvider.getItemAt(0).label == this.createRequiredPlayerListEmptyPrompt) {
					this.create_requiredPlayersList.dataProvider.removeAll();
				}
				this.create_requiredPlayersList.dataProvider.addItem({label:this.create_requiredPlayerInput.text});
				this.create_removeRequiredPlayerButton.isEnabled = true;
			}
			if (this.create_requiredPlayersList.dataProvider.length > 0) {
				this.create_numPlayersList.selectedIndex = this.create_requiredPlayersList.dataProvider.length - 1;
				this.create_numPlayersList.isEnabled = false;
				this.create_numPlayersList.invalidate();
			}
		}
		
		private function onCreateRemovePlayer(eventObj:Event):void {
			var selectedItem:Object = this.create_requiredPlayersList.selectedItem;
			this.create_requiredPlayersList.dataProvider.removeItem(selectedItem);
			if (this.create_requiredPlayersList.dataProvider.length > 0) {
				this.create_numPlayersList.selectedIndex = this.create_requiredPlayersList.dataProvider.length - 1;
				this.create_numPlayersList.isEnabled = false;
			} else {
				this.create_numPlayersList.selectedIndex = 0;
				this.create_numPlayersList.isEnabled = true;
			}
			this.create_numPlayersList.invalidate();
			if (this.create_requiredPlayersList.dataProvider.length == 0) {
				this.create_requiredPlayersList.dataProvider.addItem({label:this.createRequiredPlayerListEmptyPrompt});
				this.create_removeRequiredPlayerButton.isEnabled = false;
			}			
		}
		
		private function populateCreateContractsList():void {			
			this.create_contractsList.dataProvider = new ListCollection();
			if (lounge.ethereum == null) {
				this.create_contractsList.isEnabled = false;
				this.create_contractsList.prompt = "Ethereum is disabled";
				return;
			}
			this.create_contractsList.isEnabled = true;
			var smartContractsNode:XML = GlobalSettings.getSettingsCategory("smartcontracts");
			var ethereumNode:XML = smartContractsNode.child("ethereum")[0];
			var networkNodes:XMLList = ethereumNode.children();
			for (var count:int = 0; count < networkNodes.length(); count++) {
				var currentNetworkNode:XML = networkNodes[count];
				if ((currentNetworkNode.localName() == "network") && (currentNetworkNode.@id == lounge.ethereum.client.networkID)) {
					DebugView.addText("populating contracts list from: " + currentNetworkNode.toString());
					var contractNodes:XMLList = currentNetworkNode.children();
					for (var count2:int = 0; count2 < contractNodes.length(); count2++) {
						var currentContractNode:XML = contractNodes[count2];
						var contractName:String = currentContractNode.localName();
						var contractType:String = String(currentContractNode.@type);
						var contractStatus:String = String(currentContractNode.@status);
						var contractAddress:String = currentContractNode.child("address")[0].toString();
						if ((contractType == "contract") && ((contractStatus == "new") || (contractStatus == "available"))) {
							this.create_contractsList.dataProvider.addItem({text: contractAddress, descriptor:currentContractNode});							
						}
					}
					this.create_contractsList.selectedIndex = 0;
					return;
				}
			}
		}
		
		private function onDenominationSelect(eventObj:Event):void {
			var weiAmount:String;
			if (this.create_buyInAmount.text != "") {
				weiAmount = lounge.ethereum.web3.toWei(this.create_buyInAmount.text, this._currentDenomination);
				this.create_buyInAmount.text = lounge.ethereum.web3.fromWei(weiAmount, this.create_denominationPicker.selectedItem.unit);
			}
			if (this.create_bigBlindAmount.text != "") {
				weiAmount = lounge.ethereum.web3.toWei(this.create_bigBlindAmount.text, this._currentDenomination);
				this.create_bigBlindAmount.text = lounge.ethereum.web3.fromWei(weiAmount, this.create_denominationPicker.selectedItem.unit);
			}
			if (this.create_smallBlindAmount.text != "") {
				weiAmount = lounge.ethereum.web3.toWei(this.create_smallBlindAmount.text, this._currentDenomination);
				this.create_smallBlindAmount.text = lounge.ethereum.web3.fromWei(weiAmount, this.create_denominationPicker.selectedItem.unit);
			}
			this._currentDenomination = this.create_denominationPicker.selectedItem.unit;
		}
		
		private function onCreateTableClick(eventObj:Event):void {
			var buyInVal:Number = Number(this.create_buyInAmount.text);
			if (isNaN(buyInVal)) {
				buyInVal = 0;
			}
			var bigBlindVal:Number = Number(this.create_bigBlindAmount.text);
			if (isNaN(bigBlindVal)) {
				buyInVal = 0;
			}
			var smallBlindVal:Number = Number(this.create_smallBlindAmount.text);
			if (isNaN(smallBlindVal)) {
				buyInVal = 0;
			}
			if (buyInVal == 0) {
				StarlingViewManager.alert("Buy-in amount must be greater than 0.", "Buy-in too small", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			if (bigBlindVal == 0) {
				StarlingViewManager.alert("Big blind amount must be greater than 0.", "Big blind too small", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			if (smallBlindVal == 0) {
				StarlingViewManager.alert("Small blind amount must be greater than 0.", "Small blind too small", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			if (buyInVal <= bigBlindVal) {
				StarlingViewManager.alert("Big blind must be smaller than buy-in.", "Big blind too large", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			if (buyInVal <= smallBlindVal) {
				StarlingViewManager.alert("Small blind must be smaller than buy-in.", "Small blind too large", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			if (bigBlindVal <= smallBlindVal) {
				StarlingViewManager.alert("Small blind must be smaller than big blind.", "Small blind too large", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			var cliqueOptions:Object = new Object();
			var requiredPlayers:Array = new Array();
			var tableOptions:Object = new Object();
			for (var count:int = 0; count < this.create_requiredPlayersList.dataProvider.length; count++) {
				var currentPlayer:String = this.create_requiredPlayersList.dataProvider.getItemAt(count).label;
				if (currentPlayer != this.createRequiredPlayerListEmptyPrompt) {
					requiredPlayers.push(currentPlayer);
				}
			}
			if (requiredPlayers.length > 0) {
				requiredPlayers.push(lounge.clique.localPeerInfo.peerID);
			}
			cliqueOptions.groupName = this.create_createTableIDInput.text;
			tableOptions.tableID = this.create_createTableIDInput.text;
			tableOptions.ownerPeerID = lounge.clique.localPeerInfo.peerID;
			tableOptions.numPlayers = uint(this.create_numPlayersList.selectedItem.text);
			tableOptions.currencyUnits = this.create_denominationPicker.selectedItem.unit;
			tableOptions.buyInAmount = this.create_buyInAmount.text;
			tableOptions.bigBlindAmount = this.create_bigBlindAmount.text;
			tableOptions.smallBlindAmount = this.create_smallBlindAmount.text;
			//TODO: include this (blinds time) as customizable option in form
			tableOptions.blindsTime = "00:10:00";
			if (this.create_tableTypeToggle.isSelected) {
				cliqueOptions.password = this.create_tablePasswordInput.text;
				tableOptions.isOpen = false;
			} else {
				tableOptions.isOpen = true;
			}
			tableOptions.smartContractAddress = null;
			if (this.create_contractsList.isEnabled) {
				tableOptions.smartContractAddress = this.create_contractsList.selectedItem.text;
				if (tableOptions.smartContractAddress == "") {
					tableOptions.smartContractAddress = null;
				}
			}
			if ((this.create_contractGameRadio.isSelected) && (tableOptions.smartContractAddress==null)) {
				StarlingViewManager.alert("Can't create a contract game without a smart contract. Select a valid contract from the list or click on \"MANAGE SMART CONTRACTS\" to create one.", 
				"No smart contract", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			var newTable:Table = lounge.tableManager.newTable(cliqueOptions, requiredPlayers, tableOptions);
			this.hideCreateTable(new Event(Event.TRIGGERED));
		}
		
		private function onNewTableManagerCreated(eventObj:LoungeEvent):void {
			lounge.tableManager.removeEventListener(TableManagerEvent.TABLE_RECEIVED, this.onNewTableReceived);
			lounge.tableManager.removeEventListener(TableManagerEvent.NEW_TABLE, this.onNewTableCreated);
			lounge.tableManager.addEventListener(TableManagerEvent.TABLE_RECEIVED, this.onNewTableReceived);
			lounge.tableManager.addEventListener(TableManagerEvent.NEW_TABLE, this.onNewTableCreated);
		}
		
		private function onJoinTableClick(eventObj:Event):void {
			DebugView.addText("TableManagerWidget.onJoinTableClick");
			if ((this._currentSelectedGameListItemData["table"] == undefined) || (this._currentSelectedGameListItemData["table"] == null)) {
				DebugView.addText("   No Table instance is associated with the selected instance. Can't join!");
				var alert:Alert = StarlingViewManager.alert("Can't join the selected table because it doesn't exist.", "Table doesn't exist.", new ListCollection([{label:"OK"}]), null, true, true);
				return;
			}
			this.joinTableButton.isEnabled = false;
			var table:Table = this._currentSelectedGameListItemData.table as Table;
			table.addEventListener(TableEvent.QUORUM, this.onTableQuorum);
			//TODO: add password entry field (popup?) for closed table types
			var tablePassword:String = null;
			table.join(tablePassword);
		}
		
		private function onTableQuorum(eventObj:TableEvent):void {			
			this.hideTableList();
			DebugView.addText ("onTableQuorum");
			this.hideCreateTable();
			this.hideTableListDetails();
			this.hideStartCreateTableButton();
			lounge.tableManager.disableTableBeacons();
			lounge.loadGame("holdem_poker", eventObj.target as IRoom);
		}
		
		override public function initialize():void {
			DebugView.addText("GameSelectorWidget.initialize");
			//Do this when table manager becomes available (event broadcast from Lounge?)
			if (lounge.tableManager != null) {
				lounge.tableManager.addEventListener(TableManagerEvent.TABLE_RECEIVED, this.onNewTableReceived);
				lounge.tableManager.addEventListener(TableManagerEvent.NEW_TABLE, this.onNewTableCreated);
			} else {
				lounge.addEventListener(LoungeEvent.NEW_TABLEMANAGER, this.onNewTableManagerCreated);
				DebugView.addText ("   TableManager instance not found in current lounge instance.");
			}
			var listItemDefinition:XML = null;
			var dataChildren:XMLList = this._widgetData.children();
			for (var count:int = 0; count < dataChildren.length(); count++) {
				var currentNode:XML = dataChildren[count];
				if ((currentNode.localName() == "list") && (currentNode.@instance == "tableList")) {
					listItemDefinition = currentNode.child("listitem")[0];
					break;
				}
			}
			this.tableList.itemRendererFactory = function():IListItemRenderer {
				var renderer:GameListItemRenderer = new GameListItemRenderer(listItemDefinition, lounge, onListItemSelect);
				return renderer;
			}
			this.tableList.dataProvider = new ListCollection();	
			//Create list of all UI elements in the item detail view...
			this._listDetailViewItems = [listDetail_tableID, listDetail_ownerPeerID, listDetail_buyInAmount, listDetail_buyInAmount, 
		listDetail_smallBlindAmount, listDetail_bigBlindAmount, listDetail_blindsTime, listDetail_handContractAddress, listDetail_playersIcon,
		listDetail_openTableIcon, listDetail_closedTableIcon, listDetail_requiredPlayers, joinTableButton, cancelButton, listDetailPrompt_tableID,
		listDetailPrompt_ownerPeerID, listDetailPrompt_buyInAmount, listDetailPrompt_smallBlindAmount, listDetailPrompt_bigBlindAmount, listDetailPrompt_blindsTime,
		listDetailPrompt_handContractAddress];
			//...and store their origin points so they can be restored after being hidden
			for (count = 0; count < this._listDetailViewItems.length; count++) {
				var originObj:Object = new Object();
				originObj.target = this._listDetailViewItems[count];
				originObj.x = this._listDetailViewItems[count].x;
				originObj.y = this._listDetailViewItems[count].y;
				this._listDetailItemsOrgs.push(originObj);
			}
			//Create a list of all UI elements in the the create view...
			this._createViewItems = [create_createTableButton, create_cancelButton, create_contractGameRadio, create_funGameRadio, create_tableIDPrompt,
			create_createTableIDInput, create_newTableIDButton, create_numPlayersPrompt, create_numPlayersList, create_tableTypeToggle, 
			create_tablePasswordInput, create_requiredPlayerInput, create_addRequiredPlayerButton, create_requiredPlayersList, 
			create_removeRequiredPlayerButton, create_addRequiredPlayerArrow, create_tableTypePrompt, create_requiredPlayersPrompt, create_contractsList, 
			create_smartContractPrompt, create_manageContractsButton, create_buyInAmountPrompt, create_buyInAmount, create_denominationPicker, 
			create_bigBlindAmountPrompt, create_bigBlindAmount, create_smallBlindAmountPrompt, create_smallBlindAmount];
			//...and store their origin points so they can be restored after being hidden
			for (count = 0; count < this._createViewItems.length; count++) {
				originObj = new Object();
				originObj.target = this._createViewItems[count];
				originObj.x = this._createViewItems[count].x;
				originObj.y = this._createViewItems[count].y;
				this._createItemsOrgs.push(originObj);
			}			
			this.create_numPlayersList.dataProvider = new ListCollection();
			for (count = 2; count <= 10; count++) {
				this.create_numPlayersList.dataProvider.addItem({text:String(count)});
			}
			this.create_numPlayersList.selectedIndex = 0;
			this.create_numPlayersList.invalidate();
			this.create_tablePasswordInput.isEnabled = false;
			this.create_tablePasswordInput.prompt = "Table is open - no password needed to join";
			this._startCreateTableButtonOrigin = new Point(this.startCreateTableButton.x, this.startCreateTableButton.y);
			this.startCreateTableButton.y = this.startCreateTableButton.height * -1; //above page
			this._tableListOrigin = new Point(this.tableList.x, this.tableList.y);
			this._gameTypeRadioGroup = new ToggleGroup();
			this.create_contractGameRadio.toggleGroup = this._gameTypeRadioGroup;
			this.create_funGameRadio.toggleGroup = this._gameTypeRadioGroup;
			this.create_removeRequiredPlayerButton.isEnabled = false;
			//this.create_contractAddressInput.isEnabled = false;
			//this.create_contractAddressInput.visible = false;
			this._gameTypeRadioGroup.addEventListener(Event.CHANGE, this.onCreateGameTypeUpdate);
			this.showStartCreateTableButton();
			this.hideTableListDetails();
			this.hideCreateTable();
			this.showStartCreateTableButton();
			//this.hideAddContractButtons(true);
			this.create_requiredPlayersList.dataProvider = new ListCollection();
			this.create_requiredPlayersList.dataProvider.addItem({label:this.createRequiredPlayerListEmptyPrompt});
			this.populateCreateContractsList();
			this.create_denominationPicker.dataProvider = new ListCollection();
			this.create_denominationPicker.dataProvider.addItem({text:"Tether", unit:"tether"});
			this.create_denominationPicker.dataProvider.addItem({text:"Gether", unit:"gether"});
			this.create_denominationPicker.dataProvider.addItem({text:"Mether", unit:"mether"});
			this.create_denominationPicker.dataProvider.addItem({text:"Kether", unit:"kether"});
			this.create_denominationPicker.dataProvider.addItem({text:"Ether", unit:"ether"});
			this.create_denominationPicker.dataProvider.addItem({text:"Finney", unit:"finney"});
			this.create_denominationPicker.dataProvider.addItem({text:"Szabo", unit:"szabo"});
			this.create_denominationPicker.dataProvider.addItem({text:"Gwei", unit:"gwei"});
			this.create_denominationPicker.dataProvider.addItem({text:"Mwei", unit:"mwei"});
			this.create_denominationPicker.dataProvider.addItem({text:"Kwei", unit:"kwei"});
			this.create_denominationPicker.dataProvider.addItem({text:"wei", unit:"wei"});
			this.create_denominationPicker.selectedIndex = 4;
			this._currentDenomination = this.create_denominationPicker.selectedItem.unit;
			this.cancelButton.addEventListener(Event.TRIGGERED, this.onCancelClick);
			this.startCreateTableButton.addEventListener(Event.TRIGGERED, this.showCreateTable);
			this.create_cancelButton.addEventListener(Event.TRIGGERED, this.hideCreateTable);
			this.create_newTableIDButton.addEventListener(Event.TRIGGERED, this.generateNewGameID);
			this.create_tableTypeToggle.addEventListener(Event.CHANGE, this.onToggleCreatePassword);
			this.create_addRequiredPlayerButton.addEventListener(Event.TRIGGERED, this.onCreateAddPlayer);
			this.create_removeRequiredPlayerButton.addEventListener(Event.TRIGGERED, this.onCreateRemovePlayer);
			this.create_tablePasswordInput.text = " ";
			this.create_tablePasswordInput.text = "";
			this.create_manageContractsButton.addEventListener (Event.TRIGGERED, this.onManageSmartContractsClick);
			this.create_denominationPicker.addEventListener(Event.CHANGE, this.onDenominationSelect);
			this.create_createTableButton.addEventListener(Event.TRIGGERED, this.onCreateTableClick);			
			this.joinTableButton.addEventListener(Event.TRIGGERED, this.onJoinTableClick);
		}
		
	}

}