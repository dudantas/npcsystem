
if OtNpcSystem ~= nil then
	return
end

ACTION_NORMAL = 1
ACTION_GREET = 2
ACTION_FAREWELL = 3
ACTION_VANISH = 4
ACTION_QUEUE = 5
ACTION_IGNOREFOCUS = 6
ACTION_TRADE = 7
ACTION_TRADE_BUY = 8
ACTION_TRADE_BUY_REPLY = 9
ACTION_TRADE_SELL = 10
ACTION_TRADE_SELL_REPLY = 11

MESSAGE_DEFAULT_GREET = 1
MESSAGE_DEFAULT_WALKAWAY = 2
MESSAGE_DEFAULT_FAREWELL = 3
MESSAGE_DEFAULT_QUEUE = 4

OtNpcSystem = {
	Focus = nil,
	Actions = nil,
	TalkState = nil,
	TalkRadius = 4,
	TalkIdle = 30,
	QueueEnabled = false,
	TalkLast = nil,
	TalkQueue = nil,
	DefaultMessage = nil,
	Shop = nil,
	Trade = nil
}

function OtNpcSystem:Init()

	local obj = {}

	obj.Focus = 0
	obj.Actions = {}
	obj.TalkState = 0
	obj.TalkLast = 0
	obj.TalkQueue = {}	
	
	obj.DefaultMessage = {
		[ MESSAGE_DEFAULT_WALKAWAY ] = "How rude!",
		[ MESSAGE_DEFAULT_FAREWELL ] = "Good bye, %N!",
		[ MESSAGE_DEFAULT_GREET ] = "Hello, %N!",
		[ MESSAGE_DEFAULT_QUEUE ] = "%N, please wait for your turn."
	}
	
	obj.Shop = {
		Id = 0,
		Count = 1,
		Price = 0,
		Charges = 0,
		Amount = 1
	}
	
	obj.Trade = {}

	setmetatable( obj, self )
	self.__index = self
	
	return obj
end

function OtNpcSystem:enableQueue( value )
	
	if value then
		self.Focus = 0
		self.TalkLast = 0
		self.TalkState = 0
		self.QueueEnabled = true
		return
	end
	
	self.Focus = {}
	self.TalkLast = {}
	self.TalkState = {}
	self.QueueEnabled = false
	
end

function OtNpcSystem:onCreatureAppear( cid )
	
end

function OtNpcSystem:onCreatureDisappear( cid )

	local creature = Creature( cid )
	if not isPlayer( creature ) then
		return
	end
	
	local player = creature:getPlayer()
	if not self:isFocused( player:getId() ) then
		return
	end
	
	self:processFarewellAction( player:getId() )
	
end

function OtNpcSystem:onThink()

	if self.QueueEnabled then
		if self.Focus ~= 0 then
			if not self:isInTalkRadius( self.Focus ) then
				self:processWalkAwayAction( self.Focus )
			elseif self.TalkLast ~= 0 and ( os.time() - self.TalkLast ) > self.TalkIdle then
				self:processFarewellAction( self.Focus )
			end
		end
	else
		if #self.Focus ~= 0 then
			for pos, focus in pairs( self.Focus ) do
				if not self:isInTalkRadius( focus ) then
					self:processWalkAwayAction( focus )
				elseif self.TalkLast[ focus ] ~= 0 and ( os.time() - self.TalkLast[ focus ] ) > self.TalkIdle then
					self:processFarewellAction( focus )
				end
			end
		end
	end

	self:updateFocus()
	
end

function OtNpcSystem:onCreatureSay( cid, type, message )

	local creature = Creature( cid )
	if not creature:isPlayer() then
		return
	end

	local player = creature:getPlayer()
	if not self:isInTalkRadius( player:getId() ) then
		return
	end

	if type == TALKTYPE_MONSTER_SAY then
		return
	end

	local action = self:findAction( player:getId(), message )
	if not action then
		return
	end
	
	if action.type == ACTION_GREET then
		self:processGreetAction( player:getId(), action )
	elseif action.type == ACTION_NORMAL or action.type == ACTION_IGNOREFOCUS then
		self:processNormalAction( player:getId(), action )
	elseif action.type == ACTION_FAREWELL then
		self:processFarewellAction( player:getId(), action )
	elseif action.type == ACTION_TRADE then
		self:doOpenTradeWindow( player:getId(), action )
	end

	self:setTalkState( player:getId(), ( action.parameters.talkState ~= nil and action.parameters.talkState or 0 ) )
	
	if self.QueueEnabled then
		self.TalkLast = os.time()
	else
		self.TalkLast[ player:getId() ] = os.time()
	end

end

function OtNpcSystem:processGreetAction( cid, action )
	
	if self:isFocused( cid ) then
		if self.QueueEnabled then
			self:processQueueAction( cid )
		end
		return
	end
	
	if action ~= nil and action.parameters.reply ~= nil then
		self:processNpcSay( cid, action.parameters.reply )
	else
		local action = self:findAction( cid, ACTION_GREET )
		if not action or ( action.parameters.reply == nil ) then
			self:processNpcSay( cid, self.DefaultMessage[ MESSAGE_DEFAULT_GREET ] )
		else
			self:processNpcSay( cid, action.parameters.reply )
		end
	end

	self:addFocus( cid )

end

function OtNpcSystem:processQueueAction( cid )

	local action = self:findAction( cid, ACTION_QUEUE )
	if not action or action.parameters.reply == nil then
		self:processNpcSay( cid, self.DefaultMessage[ MESSAGE_DEFAULT_QUEUE ] )
	else	
		self:processNpcSay( cid, action.parameters.reply )
	end

	if not self:isInQueue( cid ) then
		table.insert( self.TalkQueue, cid )
	end

end

function OtNpcSystem:processFarewellAction( cid, action )
	
	if not self:isFocused( cid ) then
		return
	end
	
	if action ~= nil and action.parameters.reply ~= nil then
		self:processNpcSay( cid, action.parameters.reply )
	else
		local action = self:findAction( cid, ACTION_FAREWELL )
		if not action or ( action.parameters.reply == nil ) then
			self:processNpcSay( cid, self.DefaultMessage[ MESSAGE_DEFAULT_FAREWELL ] )
		else
			self:processNpcSay( cid, action.parameters.reply )
		end
	end

	self:releaseFocus( cid )

end

function OtNpcSystem:processWalkAwayAction( cid )
	
	if not self:isFocused( cid ) then
		return
	end
	
	local action = self:findAction( cid, ACTION_VANISH )
	if not action or ( action.parameters.reply == nil ) then
		self:processNpcSay( cid, self.DefaultMessage[ MESSAGE_DEFAULT_WALKAWAY ] )
	else
		self:processNpcSay( cid, action.parameters.reply )
	end
	
	self:releaseFocus( cid )

end

function OtNpcSystem:processNormalAction( cid, action )
	
	if not self:isFocused( cid ) and action.type ~= ACTION_IGNOREFOCUS then
		return
	end

	if action.parameters.shop ~= nil then
		self.Shop.Id = ( action.parameters.shop[1] ~= nil and tonumber( action.parameters.shop[1] ) or 0 )
		self.Shop.Count = ( ( action.parameters.shop[2] ~= nil and tonumber( action.parameters.shop[2] ) or 1 ) * self.Shop.Amount )
		self.Shop.Price = ( ( action.parameters.shop[3] ~= nil and tonumber( action.parameters.shop[3] ) or 0 ) * self.Shop.Amount )
		self.Shop.Charges = ( action.parameters.shop[4] ~= nil and tonumber( action.parameters.shop[4] ) or 0 )
	end

	if action.parameters.reply == nil then
		return
	end

	self:processNpcSay( cid, action.parameters.reply )

end









function OtNpcSystem:doOpenTradeWindow( cid, action )

	if not self:isFocused( cid ) then
		return
	end

	openShopWindow(
		cid,
		self.Trade,
		function( cid, itemid, subType, amount, ignoreCap, inBackpacks )
			self:tradeBuyCallback( cid, itemid, subType, amount, ignoreCap, inBackpacks )
		end,
		function( cid, itemid, subType, amount, ignoreCap, inBackpacks )
			self:tradeSellCallback( cid, itemid, subType, amount, ignoreCap, inBackpacks )
		end
	)

	if action.parameters.reply == nil then
		return
	end
	
	self:processNpcSay( cid, action.parameters.reply )

end

function OtNpcSystem:tradeBuyCallback( cid, itemid, subType, amount, ignoreCap, inBackpacks )
	
	local player = Player( cid )
	local shopItem = self:getTradeWindowItem( itemid, subType, true )

	if shopItem == nil or shopItem.buy == -1 then
		return false
	end

	local backpackId = 1988
	local totalCost = amount * shopItem.buy
	
	if inBackpacks then
		totalCost = isItemStackable( itemid ) == true and totalCost + 20 or totalCost + ( math.max(1, math.floor( amount / getContainerCapById( backpackId ) ) ) * 20 )
	end
	
	local subType = shopItem.subType or 1
	local a, b = doNpcSellItem( cid, itemid, amount, subType, ignoreCap, inBackpacks, backpackId )
	
	if a < amount then

		doPlayerSendCancel( cid, ( a == 0 and "You do not have enough capacity." or "You do not have enough capacity for all items." ) )

		if a > 0 then
			doPlayerRemoveMoney( cid, ( ( a * shopItem.buy ) + ( b * 20 ) ) )
			return true
		end

		return false
	end
	
	doPlayerSendTextMessage( cid, MESSAGE_INFO_DESCR, string.format( "Bought %dx %s for %d gold.", amount, ItemType( itemid ):getName(), totalCost ) )
	doPlayerRemoveMoney( cid, totalCost )

	local action = self:findAction( cid, ACTION_TRADE_BUY_REPLY )
	if action ~= false and action.parameters.reply ~= nil then
		self:processNpcSay( cid, string.gsub( action.parameters.reply, "%%P", totalCost ) )
	end

	return true
end

function OtNpcSystem:tradeSellCallback( cid, itemid, subType, amount, ignoreCap, inBackpacks )
	
	local shopItem = self:getTradeWindowItem( itemid, subType, false )
	if shopItem == nil or shopItem.sell == -1 then
		return false
	end

	if not isItemFluidContainer( itemid ) then
		subType = -1
	end
	
	local totalCost = ( amount * shopItem.sell )

	if not doPlayerRemoveItem( cid, itemid, amount, subType, ignoreEquipped ) then
		doPlayerSendCancel( cid, "You do not have this object." )
		return false
	end
	
	doPlayerSendTextMessage( cid, MESSAGE_INFO_DESCR, string.format( "Sold %dx %s for %d gold.", amount, ItemType( itemid ):getName():lower(), totalCost ) )
	doPlayerAddMoney( cid, totalCost )

	local action = self:findAction( cid, ACTION_TRADE_SELL_REPLY )
	if action ~= false and action.parameters.reply ~= nil then
		self:processNpcSay( cid, string.gsub( action.parameters.reply, "%%P", totalCost ) )
	end

	return true
end

function OtNpcSystem:getTradeWindowItem( itemId, itemSubType, onBuy )
	
	if onBuy == nil then
		return nil
	end
	
	if ItemType( itemId ):isFluidContainer() then
		for i = 1, #self.Trade do
			local shopItem = self.Trade[i]
			if shopItem.id == itemId and shopItem.subType == itemSubType then
				if not onBuy and shopItem.sell > 0 then
					return shopItem
				elseif onBuy and shopItem.buy > 0 then
					return shopItem
				end
			end
		end
	else
		for i = 1, #self.Trade do
			local shopItem = self.Trade[i]
			if shopItem.id == itemId then
				if not onBuy and shopItem.sell > 0 then
					return shopItem
				elseif onBuy and shopItem.buy > 0 then
					return shopItem
				end
			end
		end
	end

	return nil
end










function OtNpcSystem:processNpcSay( cid, message )

	local parseInfo = {
		[ "%%N" ] = Player( cid ):getName(),
		[ "%%T" ] = getFormattedWorldTime(),
		[ "%%P" ] = self.Shop.Price,
		[ "%%A" ] = self.Shop.Count
	}

	if type( message ) == "table" then
		for _, msg in pairs( message ) do
			for search, replace in pairs( parseInfo ) do
				msg = string.gsub( msg, search, replace )
			end
			selfSay( msg, cid )
		end
	else
		for search, replace in pairs( parseInfo ) do
			message = string.gsub( message, search, replace )
		end
		selfSay( message, cid )
	end

end

function OtNpcSystem:findAction( cid, value )
	
	for _, action in pairs( self.Actions ) do
		if ( ( type( value ) == "number" and action.type == value ) or ( type( value ) == "string" and self:findActionKeyword( action, value ) ) ) and self:processActionCondition( cid, action ) then
			self:processAction( cid, action )
			return action
		end
	end
	
	return false
end

function OtNpcSystem:findActionKeyword( action, message )
	
	if action.parameters.keywords ~= nil and type( action.parameters.keywords ) == "table" then
		for _, keyword in pairs( action.parameters.keywords ) do
			if self:processActionKeywords( keyword, message ) then
				return true
			end
		end
	end
	
	return false
end

function OtNpcSystem:processActionKeywords( keywords, message )

	local ret = true
	for _, keyword in pairs( keywords ) do
		local a, b = string.find( message, keyword )
		if a == nil or b == nil then
			ret = false
			break
		end
	end
	return ret
end

function OtNpcSystem:processActionCondition( cid, action )
	
	local player = Player( cid )
	if action.condition and not action.condition( player, action.parameters, self ) then
		return false
	end
	
	return true
end

function OtNpcSystem:processAction( cid, action )
	
	local player = Player( cid )
	if not action.action then
		return
	end
	
	action.action( player, action.parameters, self )

end

function OtNpcSystem:addAction( typeEx, parameters, condition, action )

	if typeEx == ACTION_TRADE_BUY or typeEx == ACTION_TRADE_SELL then
		
		if parameters.id == nil or type( parameters.id ) ~= "number" then
			return
		end
		
		table.insert( self.Trade, { id = parameters.id, buy = ( typeEx == ACTION_TRADE_BUY and parameters.price or 0 ), sell = ( typeEx == ACTION_TRADE_SELL and parameters.price or 0 ), subType = ( parameters.subType ~= nil and parameters.subType or 0 ), name = ( parameters.name ~= nil and parameters.name or ItemType( parameters.id ):getName() ) } )

		return
	end

	keywords = parameters.keywords
	parameters.keywords = {}

	table.insert( parameters.keywords, keywords )
	table.insert( self.Actions, {
		type = typeEx,
		parameters = parameters,
		condition = condition,
		action = action
	} )

end

function OtNpcSystem:addAliasAction( keywords )
	
	LastActionKeywords = self.Actions[ #self.Actions ].parameters.keywords
	
	if LastActionKeywords ~= nil and keywords ~= nil then
		table.insert( LastActionKeywords, keywords )
	end

end

function OtNpcSystem:addFocus( cid )
	
	if not self:isFocused( cid ) then
		
		if self.QueueEnabled then
			self.Focus = cid
			self.TalkLast = os.time()
		else
			self.TalkLast[ cid ] = os.time()
			table.insert( self.Focus, cid )
		end
		
		self:setTalkState( cid, 0 )
		self:updateFocus()
		
		return true
	end

	return false
end

function OtNpcSystem:releaseFocus( cid )
	
	if not self:isFocused( cid ) then
		return
	end
	
	if self.QueueEnabled then
		self.TalkState = 0
		self.TalkLast = 0
		self.Focus = 0
	else
	
		self.TalkState[ cid ] = nil
		self.TalkLast[ cid ] = nil
		self.Focus[ cid ] = nil

		local pos = nil
		for k, v in pairs( self.Focus ) do
			if v == cid then
				pos = k
			end
		end
		
		table.remove( self.Focus, pos )
		
	end
	
	closeShopWindow( cid )
	
	self.Shop.Id = 0
	self.Shop.Count = 1
	self.Shop.Price = 0
	self.Shop.Charges = 0
	self.Shop.Amount = 1

	self:updateFocus()
	
	if self.QueueEnabled then
		while self.TalkQueue[1] ~= nil do
			local nextCid = table.remove( self.TalkQueue, 1 )
			if isPlayer( nextCid ) and self:isInTalkRadius( nextCid ) then
				self:processGreetAction( nextCid )
				return true
			end
		end
	end

end

function OtNpcSystem:updateFocus()

	if self.QueueEnabled then
		doNpcSetCreatureFocus( self.Focus )
	else
		for pos, focusId in pairs( self.Focus ) do
			if focusId ~= nil then
				doNpcSetCreatureFocus( focusId )
				return
			end
		end
		doNpcSetCreatureFocus( 0 )
	end

end

function OtNpcSystem:isFocused( cid )
	
	if self.QueueEnabled then
		if self.Focus ~= 0 then
			return true
		end
	else
		for k, v in pairs( self.Focus ) do
			if v == cid then
				return true
			end
		end
	end
	
	return false
end

function OtNpcSystem:isInTalkRadius( cid )
	
	local playerPos = getPlayerPosition( cid )
	if playerPos ~= false then
		return ( self.TalkRadius >= getDistanceBetween( getCreaturePosition( getNpcCid() ), playerPos ) )
	end
	
	return false
end

function OtNpcSystem:isInQueue( cid )
	return ( isInArray( self.TalkQueue, cid ) == true )
end

function OtNpcSystem:setTalkRadius( talkRadius )
	
	self.TalkRadius = talkRadius
	
	if self.TalkRadius ~= talkRadius then
		return false
	end

	return true
end

function OtNpcSystem:getTalkRadius()
	
	if self.TalkRadius ~= nil then
		return self.TalkRadius
	end
	
	return nil
end

function OtNpcSystem:setTalkState( cid, state )
	
	if self.QueueEnabled then
		self.TalkState = state
	else
		self.TalkState[ cid ] = state
	end

	if self:getTalkState( cid ) ~= state then
		return false
	end
	
	return true
end

function OtNpcSystem:getTalkState( cid )

	if self.QueueEnabled then
		if self.TalkState ~= nil and self.TalkState ~= 0 then
			return self.TalkState
		end
	else
		if self.TalkState[ cid ] ~= nil and self.TalkState[ cid ] ~= 0 then
			return self.TalkState[ cid ]
		end
	end
	
	return 0
end

function OtNpcSystem:isWeekDay( day )
	
	if os.date( "%A" ):lower() == day:lower() then
		return true
	end
	
	return false
end

function OtNpcSystem:addBurning( cid, ticks, damage, playerEffect, npcEffect )
	
	local player = Player( cid )
	local npc = Creature( getNpcCid() )
	local condition = Condition( CONDITION_FIRE )
	
	if not player then
		return
	end
	
	if not npc then
		return
	end
	
	condition:setParameter( CONDITION_PARAM_DELAYED, 1 )
	condition:addDamage( ticks, 3000, -damage )
	
	if npcEffect ~= nil then
		npc:getPosition():sendMagicEffect( npcEffect )
	end

	if playerEffect ~= nil then
		player:getPosition():sendMagicEffect( playerEffect )
	end

	player:addCondition( condition )

end

function OtNpcSystem:setIdle( cid )
	addEvent( function( self, cid )
		self:releaseFocus( cid )
	end, 1000, self, cid )
end
