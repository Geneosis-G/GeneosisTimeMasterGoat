class DioBrandoGoat extends GGMutator
	config(Geneosis);

var array<GGGoat> dioGoats;
var config bool isDioBrandoUnlocked;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	//Function not called on custom mutators for now so this is not working
	return default.isDioBrandoUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockDioBrandoGoat()
{
	if(!default.isDioBrandoUnlocked)
	{
		PostJuice( "Unlocked Dio Brando Goat" );
		default.isDioBrandoUnlocked=true;
		static.StaticSaveConfig();
	}
}

function static PostJuice( string text )
{
	local GGGameInfo GGGI;
	local GGPlayerControllerGame GGPCG;
	local GGHUD localHUD;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGPCG = GGPlayerControllerGame( GGGI.GetALocalPlayerController() );

	localHUD = GGHUD( GGPCG.myHUD );

	if( localHUD != none && localHUD.mHUDMovie != none )
	{
		localHUD.mHUDMovie.AddJuice( text );
	}
}

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			if(!default.isDioBrandoUnlocked)
			{
				DisplayLockMessage();
			}
			else
			{
				dioGoats.AddItem(goat);
				ClearTimer(NameOf(InitDioBrandos));
				SetTimer(1.f, false, NameOf(InitDioBrandos));
			}
		}
	}

	super.ModifyPlayer( other );
}

function InitDioBrandos()
{
	local TimeMasterGoat tmg;
	local GGGoat goat;

	//Find Sonic Goat mutator
	foreach AllActors(class'TimeMasterGoat', tmg)
	{
		if(tmg != none)
		{
			break;
		}
	}

	if(tmg == none)
	{
		DisplayUnavailableMessage();
		return;
	}

	//Activate super sonic mode
	foreach dioGoats(goat)
	{
		tmg.InitDioBrandos(goat);
	}
}

function DisplayUnavailableMessage()
{
	WorldInfo.Game.Broadcast(self, "Dio Brando Goat only works if combined with Time Master Goat.");
	SetTimer(3.f, false, NameOf(DisplayUnavailableMessage));
}

function DisplayLockMessage()
{
	ClearTimer(NameOf(DisplayLockMessage));
	WorldInfo.Game.Broadcast(self, "Dio Brando Goat Locked :( Find the Dio Brando easter egg to unlock it.");
	SetTimer(3.f, false, NameOf(DisplayLockMessage));
}

DefaultProperties
{

}