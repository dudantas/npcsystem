local npc = OtNpcSystem:Init()

npc:setTalkRadius( 3 )
npc:enableQueue( false )

function onCreatureAppear( cid )
	npc:onCreatureAppear( cid )
end

function onCreatureDisappear( cid )
	npc:onCreatureDisappear( cid )
end

function onCreatureSay( cid, type, msg )
	npc:onCreatureSay( cid, type, msg )
end

function onThink()
	npc:onThink()
end

npc:addAction(
	ACTION_GREET,
	{
		keywords = { "hi", "frodo$" },
		reply = "Hello, hello, %N. You heard about the news?"
	}
)

npc:addAliasAction( { "hello", "frodo$" } )

npc:addAction(
	ACTION_GREET,
	{
		keywords = { "hi$" },
		reply = "Welcome to Frodo's Hut. You heard about the news?"
	}
)

npc:addAliasAction( { "hello$" } )

npc:addAction(
	ACTION_FAREWELL,
	{
		keywords = { "bye$" },
		reply = "Please come back from time to time."
	}
)

npc:addAliasAction( { "farewell$" } )

npc:addAction(
	ACTION_VANISH,
	{
		reply = "Please come back from time to time."
	}
)

npc:addAction(
	ACTION_NORMAL,
	{
		keywords = { "the", "epiphany$" },
		shop = { 8931, 1, 50000 },
		reply = "Do you want to buy a the epiphany for %P gold coins?",
		talkState = 1
	}
)

npc:addAction(
	ACTION_NORMAL,
	{
		keywords = { "yes$" },
		reply = "Thank you. Here it is."
	},
	function( player, parameters, self )
		return self:getTalkState( player:getId() ) == 1 and player:getMoney() >= self.Shop.Price
	end,
	function( player, parameters, self )
		player:removeMoney( self.Shop.Price )
		player:addItem( self.Shop.Id, self.Shop.Amount )
	end
)

npc:addAction(
	ACTION_NORMAL,
	{
		keywords = { "yes$" },
		reply = "Sorry, you do not have enough soul orbs."
	},
	function( player, parameters, self )
		return self:getTalkState( player:getId() ) == 1
	end
)

npc:addAction(
	ACTION_NORMAL,
	{
		keywords = { "" },
		reply = "Maybe you will buy it another time."
	},
	function( player, parameters, self )
		return self:getTalkState( player:getId() ) == 1
	end
)
