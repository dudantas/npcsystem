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
	ACTION_TRADE,
	{
		keywords = { "trade$" },
		reply = "See my wares."
	}
)

npc:addAction(
	ACTION_TRADE_BUY,
	{
		id = 2478,
		price = 195,
		name = "brass legs"
	}
)

npc:addAction(
	ACTION_TRADE_SELL,
	{
		id = 2478,
		price = 150,
		name = "brass legs"
	}
)
