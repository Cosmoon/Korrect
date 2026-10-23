local _, ns = ...

-- Handwritten vocabulary and ranking hints. These are not dictionary imports.
-- Shared chat jargon only. Places, NPCs, items and spells come from client layers.
ns.WowWords = [[
warcraft azeroth wow classic forever retail addon addons minimap spellcheck spellchecker spellchecking
aggro dps aoe dot dots hot hots los gcd cooldown cooldowns buff buffs debuff debuffs
pvp pve pally pala hearth hearthstone hearthstones hearthing hearthstoning rez rezz res rezzing
rezzed ressing ressed mana tanking taunt taunts taunting raid raids raiding raider raiders guildie guildies
whisper whispers whispering pug pugs pugging lfg lfm afk brb gg wp ty thx np btw imo imho lol lmao rofl
omw oom oomw inc cc ccing bop boe bis wb wbs wbuff worldbuff worldbuffs consumables consumes flask flasks
elixir elixirs pot pots potion potions loot looted looting ninja ninjas pull pulls pulling wipe wipes wiped
wiping respawn respawns respawning mobs mob boss bosses adds alt alts main twink twinks twinking leveling
lvl lvls xp exp rested quest quests questing quester questers mount mounts mounted mounting dismount
summon summons summoning summoned summ port ports portal portals lockout lockouts attune attuned
attunement attunements spec specs specced speccing respec respecced respeccing talent talents professions
reagents reagent vendor vendors vendoring AH auctionhouse DKP SR MS OS need greed boomy boomkin feral
resto prot ret holy disc enh ele destro affli bm mm hc hardcore ssf zug zugzug kek kekw
]]

-- Ordered rough familiarity hints, used only after edit distance.
ns.CommonWords = [[
the of and to a in is you that it he was for on are as with his they I at be
this have from or one had by word but not what all were we when your can
said there use an each which she do how their if will up other about out
many then them these so some her would make like him into time has look
two more write go see number no way could people my than first water
been call who now find long down day did get come made may part over
new sound take only little work know place year live me back give most
very after thing our just name good sentence think say great where help
through much before right too mean tell does set three want air well
also play small end put home read hand need large spell add even land
here must big high such follow why ask change went light kind off house
try us again point world near build self earth head stand own page should
country found answer school grow study still learn plant cover food sun
four between state keep eye never last let thought city tree cross farm
hard start might story saw far sea draw left late run while press close
night real life few north open seem together next white children begin
got walk example ease paper often always music those both mark book
letter until mile river car feet care second group carry rain eat room
friend friends idea fish mountain stop once base hear horse cut sure watch
color face wood main enough plain girl usual young ready above ever red
list though feel talk bird soon body dog family direct pose leave song
measure door product black short class wind question happen complete
ship area half rock order fire south problem piece told knew pass since
top whole king space heard best hour better true during hundred five
remember step early hold west ground interest reach fast verb sing listen
six table travel less morning ten simple several vowel toward war lay
against pattern slow center love person money serve appear road map
science rule govern pull cold notice voice fall power town fine certain
unit lead cry dark machine note wait plan figure star box noun field rest
correct able pound done beauty drive stood contain front teach week final
gave green oh quick develop sleep warm free minute strong special mind
behind clear tail produce fact street inch multiply nothing course stay
wheel full force blue object decide surface deep moon island foot yet busy
test record boat common gold possible plane stead dry wonder laugh
thousand ago ran check game shape yes hot miss brought heat snow bed bring
sit perhaps fill east weight language among hello thanks thank please
sorry welcome goodbye spelling spelled spellchecker misspell misspelled
mistake mistakes message messages chat guild party raid tank healer damage
healing dungeon invite online offline tomorrow today yesterday really
because actually definitely separate receive weird believe beautiful
necessary available awesome someone anyone everyone something anything
everything looking coming going getting making doing playing waiting
level levels equipment weapon weapons armor quest server character
characters account option options settings button minimap
]]

ns.TypoHints = {
	misspeld = "misspelled", misspelld = "misspelled", mispelled = "misspelled",
	mispeld = "misspelled",
	teh = "the", recieve = "receive", recive = "receive", definately = "definitely",
	definetly = "definitely", seperate = "separate", becuase = "because",
	becasue = "because", wierd = "weird", alot = "a lot", thier = "their",
	freind = "friend", freinds = "friends", tommorow = "tomorrow",
	tommorrow = "tomorrow", mesage = "message", guilde = "guild",
}
