class TimeMasterGoatComponent extends GGPlayersOnlyComponent;

var GGGoat gMe;
var GGMutator myMut;
var AudioComponent mAC;
var SoundCue tpSound;
var TeleportRing tpRing;
var float tpRange, radius, height;
var float oldStrafeSpeed;
var float oldWalkSpeed;
var float oldReverseSpeed;
var float oldSprintSpeed;
var vector lockedLocation;
var bool lastPlayerOnly;
var bool mIsRightClicking;
var bool mIsTimeShiftActive;

var bool isDioBrando;
var bool isDioBrandoAllowed;
var SoundCue theWorld;
var SoundCue theWorldEnd;
var SoundCue TWHorn;
var SoundCue TWKick;
var SoundCue TWBite;
var SoundCue TWBaa;
var SkeletalMesh mRippedGoatMesh;
var Material mAngelMaterial;
var MaterialInstanceConstant mMaterialInstanceConstant;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		gMe.SetTimer( 1.f, false, NameOf( AllowDioBrando ), self);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ))
		{
			mIsRightClicking=true;
			EnableTimeShift(true);
		}

		if( localInput.IsKeyIsPressed( "GBA_SlowMotion", string( newKey ) ) )
		{
			if(mIsRightClicking)
			{
				PlayersOnly();

				if( gMe.WorldInfo.bPlayersOnly || gMe.WorldInfo.bPlayersOnlyPending)
				{
					TimeMasterGoat(myMut).StopSound(true);
				}
				else
				{
					TimeMasterGoat(myMut).StopSound(false);
				}
				GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).SetSlomo(false);
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ) )
		{
			Teleport();
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ))
		{
			mIsRightClicking=false;
			EnableTimeShift(false);
		}
	}
}

function EnableTimeShift(bool enable)
{
	if(mIsTimeShiftActive == enable)
		return;

	mIsTimeShiftActive=enable;
	if(mIsTimeShiftActive)
	{
		oldStrafeSpeed=gMe.mStrafeSpeed;
		oldWalkSpeed=gMe.mWalkSpeed;
		oldReverseSpeed=gMe.mReverseSpeed;
		oldSprintSpeed=gMe.mSprintSpeed;
		gMe.mStrafeSpeed=0.f;
		gMe.mWalkSpeed=0.f;
		gMe.mReverseSpeed=0.f;
		gMe.mSprintSpeed=0.f;
		if(gMe.mIsRagdoll)
		{
			gMe.StandUp();
		}
		lockedLocation=gMe.Location;
	}
	else
	{
		gMe.mStrafeSpeed=oldStrafeSpeed;
		gMe.mWalkSpeed=oldWalkSpeed;
		gMe.mReverseSpeed=oldReverseSpeed;
		gMe.mSprintSpeed=oldSprintSpeed;
		gMe.mIsRagdollAllowed=true;
		lockedLocation=vect(0, 0, 0);
	}
}

//Only allow dio brando if you don't start with ripped goat
function AllowDioBrando()
{
	if(gMe.Mesh.SkeletalMesh != mRippedGoatMesh)
	{
		isDioBrandoAllowed=true;
	}
}

function ForceDioBrando()
{
	if(isDioBrando)
		return;

	isDioBrandoAllowed=true;
	gMe.mesh.SetSkeletalMesh(mRippedGoatMesh);
}

event TickMutatorComponent( float deltaTime )
{
	local bool newPlayerOnly;

	super.TickMutatorComponent(deltaTime);

	radius=gMe.GetCollisionRadius();
	height=gMe.GetCollisionHeight();

	if(tpRing == none)
	{
		tpRing=gMe.Spawn(class'TeleportRing');
	}

	if(isDioBrandoAllowed && !isDioBrando)
	{
		if(gMe.Mesh.SkeletalMesh == mRippedGoatMesh)
		{
			MakeDioBrando();
		}
	}

	CalcRingLocation();
	if(mIsRightClicking)
	{
		tpRing.SetHidden(false);
		if(lockedLocation != vect(0, 0, 0))
		{
			SetPositionAndRotation(lockedLocation);
		}
		else
		{
			SetPositionAndRotation(gMe.Location);
		}
	}
	else
	{
		tpRing.SetHidden(true);
	}

	//Fix superspeed ragdoll glitch after entering water when time was stopped
	newPlayerOnly=gMe.WorldInfo.bPlayersOnly || gMe.WorldInfo.bPlayersOnlyPending;
	if(newPlayerOnly != lastPlayerOnly)
	{
		if(!newPlayerOnly)
		{
			gMe.SetTimer( 0.1f, false, NameOf( gMe.AllowRagdoll ));
		}
	}
	if(newPlayerOnly)
	{
		gMe.mIsRagdollAllowed=false;
	}
	lastPlayerOnly=newPlayerOnly;
}

function MakeDioBrando()
{
	local color gold;
	local LinearColor newColor;

	if(isDioBrando)
		return;

	isDioBrando=true;
	class'DioBrandoGoat'.static.UnlockDioBrandoGoat();
	mStartPlayersOnlySound=theWorld;
	mStopPlayersOnlySound=theWorldEnd;
	gMe.mBaaSoundCue=TWBaa;
	gMe.mesh.SetMaterial(0, mAngelMaterial);
	mMaterialInstanceConstant = gMe.mesh.CreateAndSetMaterialInstanceConstant(0);
	gold = MakeColor(218, 145, 0, 255);
	newColor = ColorToLinearColor(gold);
	mMaterialInstanceConstant.SetVectorParameterValue('color', newColor);
}

/**
 * See super.
 */
function OnChangeState( Actor actorInState, name newStateName )
{
	super.OnChangeState( actorInState, newStateName );

	if(isDioBrando && actorInState == gMe)
	{
		if(newStateName == 'AbilityHorn')
		{
			gMe.PlaySound( TWHorn );
		}
		if(newStateName == 'AbilityKick')
		{
			gMe.PlaySound( TWKick );
		}
		if(newStateName == 'AbilityBite')
		{
			gMe.PlaySound( TWBite );
		}
	}
}

function CalcRingLocation()
{
	local vector dest;
	local vector offset, camLocation;
	local rotator camRotation;
	local vector traceStart, traceEnd, hitLocation, hitNormal;
	local Actor hitActor;

	if(gMe.Controller != none)
	{
		GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
	}
	else
	{
		camLocation=gMe.Location;
		camRotation=gMe.Rotation;
	}
	traceStart = camLocation;
	traceEnd = traceStart;
	traceEnd += (vect(1, 0, 0)*(tpRange + VSize2D(camLocation-gMe.Location))) >> (camRotation + (rot(1, 0, 0)*10*DegToUnrRot));

	foreach gMe.TraceActors( class'Actor', hitActor, hitLocation, hitNormal, traceEnd, traceStart )
	{
		if(hitActor == tpRing || hitActor == gMe || hitActor.Base == gMe || hitActor.Owner == gMe)
		{
			continue;
		}

		break;
	}

	if(hitActor == none)
	{
		hitLocation=traceEnd;
	}

	offset=hitNormal;
	offset.Z=0;
	dest = hitLocation + Normal(offset)*(radius + 1.f);

	if(hitActor == none || hitNormal.Z < 0.5f)
	{
		traceStart = dest;
		traceEnd = dest;
		traceEnd += vect(0, 0, 1)*-100000.f;

		hitActor = gMe.Trace( hitLocation, hitNormal, traceEnd, traceStart);
		if(hitActor != none)
		{
			dest=hitLocation;
		}
	}

	tpRing.SetLocation(dest);
}

function Teleport()
{
	local vector dest, destUp, destAway, oldLoc;
	local float i, j;

	if(!mIsRightClicking || gMe.mIsRagdoll)
		return;

	if( mAC == none || mAC.IsPendingKill() )
	{
		mAC = gMe.CreateAudioComponent( tpSound, false );
		mAC.HighFrequencyGainMultiplier = 8.f;
		mAC.PitchMultiplier = 8.f;
	}
	if( mAC.IsPlaying() )
	{
		mAC.Stop();
	}
	mAC.Play();
	//PlaySound( tpSound );

	dest=tpRing.Location;
	dest.Z+=height;
	destAway=dest;
	destUp=dest;

	gMe.SetPhysics(PHYS_Falling);
	gMe.Velocity=vect(0, 0, 0);
	oldLoc=gMe.Location;
	SetPositionAndRotation(dest);

	if(gMe.Location != dest)
	{
		for(i=0 ; i<=10 ; i+=1)
		{
			//myMut.WorldInfo.Game.Broadcast(myMut, "try away");
			if(i>0)
			{
				destAway=oldLoc-dest;
				destAway.Z=0.f;
				destAway=Normal(destAway)*(i*radius/10.f);
				SetPositionAndRotation(destAway);
				if(gMe.Location == destAway)
				{
					break;
				}
			}

			for(j=0 ; j<=10 ; j+=1)
			{
				if(i != j && i != 0 && j != 0)
				{
					continue;
				}
				//myMut.WorldInfo.Game.Broadcast(myMut, "try up");
				destUp=destAway;
				destUp.Z+=j*height/10.f;
				SetPositionAndRotation(destUp);
				if(gMe.Location == destUp)
				{
					break;
				}
			}

			if(gMe.Location == destUp)
			{
				break;
			}
		}
	}
	// Emergency teleport to old location if all locations failed
	if(IsTooFarFromDest(gMe.Location, dest))
	{
		SetPositionAndRotation(oldLoc);
	}

	//myMut.WorldInfo.Game.Broadcast(myMut, "tmp=" $ tmp);
	//myMut.WorldInfo.Game.Broadcast(myMut, "dest=" $ dest);
	//myMut.WorldInfo.Game.Broadcast(myMut, "Location=" $ gMe.Location);
	lockedLocation=vect(0, 0, 0);
}

function SetPositionAndRotation(vector oldLoc)
{
	local vector camLocation;
	local rotator NewRotation, camRotation;
	local GGPlayerControllerGame GPC;

	if(gMe.Controller == none)
		return;

	gMe.mIsRagdollAllowed=false;

	gMe.SetLocation(oldLoc);
	gMe.Velocity=vect(0, 0, 0);

	GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
	NewRotation = rot(0, 0, 0);
	NewRotation.Yaw = camRotation.Yaw;
	gMe.SetRotation( NewRotation );

	GPC = GGPlayerControllerGame( gMe.Controller );
	GPC.mRotationRate = rot(0, 0, 0);
	gMe.mTotalRotation = rot( 0, 0, 0 );
}

function bool IsTooFarFromDest(vector pos, vector dest)
{
	local float dist;

	dist=VSize(pos-dest);

	return (dist*dist > radius*radius + height*height + 1.f);
}

defaultproperties
{
	tpRange=2000.f;
	tpSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Wheel_Of_Time_Time_Resumed_Cue'
	//tpSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Cow_Lazer_Cue'
	theWorld=SoundCue'TimeMasterSounds.The_World_Cue'
	theWorldEnd=SoundCue'TimeMasterSounds.The_World_End_Cue'
	TWHorn=SoundCue'TimeMasterSounds.Ability_Horn_Cue'
	TWKick=SoundCue'TimeMasterSounds.Ability_Kick_Cue'
	TWBite=SoundCue'TimeMasterSounds.Ability_Bite_Cue'
	TWBaa=SoundCue'TimeMasterSounds.Baa_Cue'
	mRippedGoatMesh=SkeletalMesh'goat.mesh.GoatRipped'
	mAngelMaterial=Material'goat.Materials.Goat_Mat_03'
}