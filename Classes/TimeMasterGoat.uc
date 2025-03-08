class TimeMasterGoat extends GGMutator;

var bool soundStopped;
var array<TimeMasterGoatComponent> mComponents;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local TimeMasterGoatComponent timeComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		timeComp=TimeMasterGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'TimeMasterGoatComponent', goat.mCachedSlotNr));
		if(timeComp != none && mComponents.Find(timeComp) == INDEX_NONE)
		{
			mComponents.AddItem(timeComp);
		}
	}
}

simulated function StopSound(bool stop)
{
	local GGPlayerControllerBase goatPC;
	local GGProfileSettings profile;

	if(stop == soundStopped)
		return;

	soundStopped=stop;

	goatPC=GGPlayerControllerBase( GetALocalPlayerController() );
	profile = goatPC.mProfileSettings;

	if(stop)
	{
		goatPC.SetAudioGroupVolume( 'Music', 0.f);
		goatPC.SetAudioGroupVolume( 'SFX', 0.f);
		goatPC.SetAudioGroupVolume( 'NPC_VO', 0.f);
	}
	else
	{
		goatPC.SetAudioGroupVolume( 'Music', profile.GetMusicVolume());
		goatPC.SetAudioGroupVolume( 'SFX', profile.GetSoundEffectsVolume());
		goatPC.SetAudioGroupVolume( 'NPC_VO', profile.GetVoiceVolume());
	}
}

function InitDioBrandos(GGGoat goat)
{
	local TimeMasterGoatComponent tmgc;

	foreach mComponents(tmgc)
	{
		if(tmgc.gMe == goat)
		{
			tmgc.ForceDioBrando();
			break;
		}
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'TimeMasterGoatComponent'
}