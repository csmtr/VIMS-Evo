GIMSVersion = 12
Global startTime = timeStamp(),
SharedCore, GameCore, strGUI, endTime

if HiddenDOSCommand != undefined then (
	global	GIMS, uEvoGIMS,
	startupPath = ( Append ScriptsPath "Startup\\" )

	try ( CloseUtility uEvoGIMS )	catch ()
	uEvoGIMS = undefined

	struct SharedCore (
		ServerURL,
		Tag = "Shared",
		Name = "Shared",
		BasePath, FilesPath, BackupPath, DownloadPath, CachePath, ResourceCachePath,
		Core, Rules,
		Loaded = false,
		WindowLayouts = #( ),
		IsUpdateDeclined = false,
		DevInfoPropList = #( #Tag, #ServerURL, #BasePath, #FilesPath, #CachePath, #ResourceCachePath, #DownloadPath, #BackupPath, #Core, #Rules, #Loaded, #WindowLayouts, #Init, #Start ),
		
		fn FileDelete FilePath = (
			try (
				if ( DoesFileExist FilePath ) then (
					local	Result = false
					for i = 1 to 3 while not Result do (
						Result = (
							( DeleteFile FilePath ) and
							( not ( DoesFileExist FilePath ) )
						)
					)
					if not Result then (
						messageBox ( "Line: 61 - Delete " + FilePath + " manually before pressing OK." ) title:"GIMS Error:" beep:true
						Result = ( not ( DoesFileExist FilePath ) )
					)
					Result
				) else (
					true
				)
			) catch (
				false
			)
		),
		
		fn FileRename SourcePath TargetPath = (
			try (
				if ( DoesFileExist SourcePath ) then (
					if ( FileDelete TargetPath ) then (
						local	Result = false,
						FileDir = ( GetFileNamePath TargetPath )
						for i = 1 to 3 while not Result do
						Result = ( MakeDir FileDir All:true )
						if not Result then (
							messageBox ( "Line 80 - Create " + FileDir + " manually before pressing OK." ) title:"GIMS Error:" beep:true
							Result = ( DoesFileExist FileDir )
						)
						if Result then (
							Result = false
							for i = 1 to 3 while not Result do
							Result = ( RenameFile SourcePath TargetPath )
							if not Result then (
								messageBox ( "Line 88 - Rename or move " + SourcePath + " to " + TargetPath + " manually before pressing OK." ) title:"GIMS Error:" beep:true
								Result = ( DoesFileExist TargetPath )
							)
						)
						Result
					) else
					false
				) else
				false
			) catch (
				false
			)
		),
		fn FileCopy SourcePath TargetPath = (
			try (
				if ( DoesFileExist SourcePath ) then (
					if ( FileDelete TargetPath ) then (
						local	Result = false,
						FileDir = ( GetFileNamePath TargetPath )
						for i = 1 to 3 while not Result do
						Result = ( MakeDir FileDir All:true )
						if not Result then (
							messageBox ( "Line 110 - Create " + FileDir + " manually before pressing OK." ) title:"GIMS Error:" beep:true
							Result = ( DoesFileExist FileDir )
						)
						if Result then (
							Result = false
							for i = 1 to 3 while not Result do
							Result = ( CopyFile SourcePath TargetPath )
							if not Result then (
								messageBox ( "Line 118 - Copy " + SourcePath + " to " + TargetPath + " manually before pressing OK." ) title:"GIMS Error:" beep:true
								Result = ( DoesFileExist TargetPath )
							)
						)
						Result
					) else (
						false
					)
				) else (
					false
				)
			) catch (
				false
			)
		),
		fn Start Game NoEH:false = (
			/*@<GUIDE>
				Creates all core related directories.
				If core launcher's found by (FilesPath + GIMS.CoreFile) path, calling it with <MXSFunction> FileIn, thereby loading the core.
				Otherwise:
				-Deletes all core related files, 
				-Downloads (ServerURL + Tag + "\\" + GIMS.FilesDir + GIMS.CoreFile) URL to (FilesPath) directory. If succeeded, calling it with <MXSFunction> FileIn, thereby loading the core.
				-Otherwise - sets the execution result to false.
			
				Sets (Loaded) field to the execution result.
				
				Returns execution result.
			*/
			local Result = false,
			CoreFile = GIMS.CoreFile,
			CoreFilePath = ( FilesPath + CoreFile ),
			StarChar = "*"

			GIMS.CurrentGame = Game
			if ( MakeDir BasePath All:true and MakeDir FilesPath All:true and MakeDir BackupPath All:true and MakeDir CachePath All:true and MakeDir ResourceCachePath All:true and MakeDir DownloadPath All:true ) then (
				if ( DoesFileExist CoreFilePath ) then (
					GIMS.CoreLoader = unsupplied
					FileIn CoreFilePath Quiet:true
					local	CoreLoader = GIMS.CoreLoader
					case CoreLoader of (
						#EULARejected:
						return()
						unsupplied:
						throw "GIMS core loader's unsupplied"
						Default:
						Result = ( CoreLoader true )
					)
				) else (
					Loaded = false
					local	Files = (
						if GIMS.IsDevBuild then
						#( )
						else (
							GetFiles ( FilesPath + StarChar ) +
							GetFiles ( CachePath + StarChar ) +
							GetFiles ( ResourceCachePath + StarChar )
						)
					)
					for tFile in Files do
					DeleteFile tFile
					local	URL = ( StringStream "" )
					Format "%%/%%" ServerURL Tag GIMS.FilesDir CoreFile To:URL
					if ( GIMS.Download #( URL as string ) DownloadPath true ) then (
						try (
							FileIn ( DownloadPath + CoreFile ) Quiet:true
							local	CoreLoader = GIMS.CoreLoader
							case CoreLoader of (
								#EULARejected:
								return()
								unsupplied:
								throw "GIMS core loader's unsupplied"
								Default: (
									try (
										Result = ( CoreLoader true )
									) catch (
										messageBox ( "Line: 193 - Can't load the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
									)
								)
							)
						) catch (
							messageBox ( "Line: 198 - Can't compile the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
						)
					) else (
						messageBox ( "Line: 201 - Failed to download the " + ( Name as String ) + " core." ) title:"GIMS Error:" beep:true
						Free URL
					)
				)
			) else (
				messageBox ( "Line: 206 - Failed to create folders." ) title:"GIMS Error:" beep:true
			)
			
			
			Loaded = ( Result == true )
			Result
		),

		fn Init GIMS = (
			Tag = "Shared"
			Name = "Shared"
			try (
				if ( ServerURL == undefined ) then (
					ServerURL = GIMS.ServerURL
				) else (
					GIMS.ServerURL = ServerURL
				)
				BasePath = ( Append ( GIMS.GIMSPath + ( Tag as String ) ) "/" )
				FilesPath = ( BasePath + GIMS.FilesDir )
				BackupPath = ( BasePath + GIMS.BackupDir )
				CachePath = ( BasePath + GIMS.CacheDir )
				ResourceCachePath = ( CachePath + GIMS.ResourceCacheDir )
				DownloadPath = ( BasePath + GIMS.DownloadDir )
			) catch (
				messageBox ( "Line: 232 - Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
			)
		)
	)
	struct GameCore (
		Tag = "NONE",
		Name = "NONE",
		ServerURL,
		BasePath, FilesPath, BackupPath, DownloadPath, CachePath, ResourceCachePath,
		Core, Rules,
		Installed, Loaded,
		WindowLayouts = #( ),
		IsUpdateDeclined = false,
		DevInfoPropList = #( #Tag, #Name, #ServerURL, #BasePath, #FilesPath, #CachePath, #ResourceCachePath, #DownloadPath, #BackupPath, #Core, #Rules, #Installed, #Loaded, #WindowLayouts, #Install, #Init, #Start, #UnInstall ),

		fn Init GIMS = (
			try (
				if ( ServerURL == undefined ) then ( ServerURL = GIMS.ServerURL )
				BasePath = ( Append ( GIMS.GIMSPath + ( Tag as String ) ) "/" )
				FilesPath = ( BasePath + GIMS.FilesDir )
				BackupPath = ( BasePath + GIMS.BackupDir )
				CachePath = ( BasePath + GIMS.CacheDir )
				ResourceCachePath = ( CachePath + GIMS.ResourceCacheDir )
				DownloadPath = ( BasePath + GIMS.DownloadDir )
				Loaded = false
				Installed = ( DoesFileExist ( FilesPath + GIMS.CoreFile ) )
				Core = undefined
			) catch (
				messageBox ( "Line: 254 - Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
			)
		),

		fn UnInstall = (
			local	StarChar = "*",
			Files = (
				if ( GIMS.IsDevBuild ) then (
					#( )
				) else (
					GetFiles ( FilesPath + StarChar ) +
					GetFiles ( CachePath + StarChar ) +
					GetFiles ( ResourceCachePath + StarChar ) +
					GetFiles ( DownloadPath + StarChar )
				)
			)
			for tFile in Files do
			DeleteFile tFile
			Init GIMS
		),

		fn Install Game = (
			local Result = false,
			CoreFile = GIMS.CoreFile
			try (
				GIMS.CurrentGame = Game
				UnInstall()
				if (
					MakeDir BasePath All:true and
					MakeDir FilesPath All:true and
					MakeDir BackupPath All:true and
					MakeDir DownloadPath All:true and
					MakeDir CachePath All:true and
					MakeDir ResourceCachePath All:true
				) then (
					local	URL = ( StringStream "" )
					Format "%%/%%" ServerURL Tag GIMS.FilesDir CoreFile To:URL
					if ( GIMS.Download #( URL as String ) DownloadPath true ) then (
						try (
							FileIn ( DownloadPath + CoreFile ) Quiet:true
							try (
								Result = ( GIMS.CoreLoader true )
							) catch (
								messageBox ( "Line: 341 - Can't load the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
							)
						) catch (
							messageBox ( "Line: 344 - Can't compile the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
						)
					) else
					messageBox ( "Line: 347 - Failed to download the " + ( Name as String ) + " core." ) title:"GIMS Error:" beep:true
					Free URL
				) else
				messageBox ( "Line: 350 - Failed to create folders." ) title:"GIMS Error:" beep:true
			) catch (
				messageBox ( "Line: 352 - Can't install the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
			)
			Loaded = Result
			Installed = Result
			Result
		),

		fn Start Game NoEH:false = (
			local Result = false
			try (
				GIMS.CurrentGame = Game

				if (
					MakeDir BasePath All:true and
					MakeDir FilesPath All:true and
					MakeDir BackupPath All:true and
					MakeDir DownloadPath All:true and
					MakeDir CachePath All:true and
					MakeDir ResourceCachePath All:true
				) then (
					local	CoreFile = ( FilesPath + GIMS.CoreFile )
					if ( DoesFileExist CoreFile ) then (
						try (
							local	IsFirstLaunch = ( Core == undefined )
							if IsFirstLaunch then
							FileIn CoreFile Quiet:true
							try (
								Result = ( GIMS.CoreLoader IsFirstLaunch )
							) catch (
								Core = undefined
								messageBox ( "Line: 389 - Can't load the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
							)
						) catch (
							messageBox ( "Line: 392 - Can't compile the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
						)
					) else
					Result = ( Install Game )
				) else
				messageBox ( "Line: 397 - Failed to create folders." ) title:"GIMS Error:" beep:true
			) catch (
				if NoEH then
				throw()
				messageBox ( "Line: 401 - Can't start the " + ( Name as String ) + " core. Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
			)
			Loaded = Result
			Result
		)
	)
	struct GUIFontTip (
		Regular,
		SemiBold
	)
	struct GUIFontBody (
		Regular,
		SemiBold
	)
	struct GUIFontSubHeader (
		Regular,
		Light
	)
	struct GUIFont (
		Header,
		SubHeader = GUIFontSubHeader(),
		Body = GUIFontBody(),
		Tip = GUIFontTip(),
		/*@<Boolean>*/ fn Check = (
			/*@<GUIDE>
				Checks structure fields to be initialized properly
			*/
			(
				Header != undefined and
				SubHeader.Regular != undefined and
				SubHeader.Light != undefined and
				Body.Regular != undefined and
				Body.SemiBold != undefined and
				Tip.Regular != undefined and
				Tip.SemiBold != undefined
			)
		)
	)
	struct GUIColour (
		SDC,
		CBlack,
		CWhite,
		CGray,
		Theme,
		Accent,
		Warning,
		Transparent,
		Info,
		/*@<Boolean>*/ fn Check = (
			/*@<GUIDE>
				Checks structure fields to be initialized properly
			*/
			(
				SDC != undefined and
				CBlack != undefined and
				CWhite != undefined and
				CGray != undefined and
				Theme != undefined and
				Accent != undefined and
				Warning != undefined and
				Transparent != undefined and
				Info != undefined
			)
		)
	)
	struct strGUI (
		BitmapPath,
		Images = #( #( ), #( ) ),
		Font = GUIFont(),
		Colour = GUIColour(),
		Align,
		ScrollOrientation,
		NameSeparator = "_",
		ImageExt = ".png",
		/*@<BitMap>*/ fn SaveBitMap /*@<BitMap>*/ TheBMP = (
			/*@<GUIDE>
				Saves the bitmap adnd opens it again.
				returns the BitMap, or "undefined" if saving\opening failed.
			*/
			local	FileName = TheBMP.FileName
			if FileName.Count == 0 then
			throw "Can't Save the BitMap without a FileName"
			Save TheBMP Gamma:1
			Close TheBMP
			if not ( DoesFileExist FileName ) then
			throw "Can't save the bitmap: " FileName
			try
			OpenBitmap FileName
			catch
			undefined
		),
		/*@<BitMap>*/ fn ResizeBitmap /*@<BitMap>*/ TheBMP /*@<Point2>*/ Size /*@<String>*/ FilePath:undefined DoSave:true = (
			/*@<GUIDE>
				Resizes the bitmap with using the parameter "Size".
				Saves the bitmap to the path from "FilePath" parameter if it's defined, otherwise by the following formula:
					<Shared core resource cache path>/R-G-B-A_WidthxHeight.png
				returns the BitMap, or "undefined" if saving\opening failed.
			*/
			local	Width = Size.x,
			Height = Size.y
			if FilePath == undefined then (
				local	SS = ( StringStream "" )
				Format "%%_%x%.png" GIMS.Shared.ResourceCachePath ( GetHashValue TheBMP.FileName 0 ) Width Height To:SS
				FilePath = ( SS as string )
				Free SS
			)
			local	ResizedBMP = ( BitMap Width Height FileName:FilePath )
			Copy TheBMP ResizedBMP
			if DoSave then
			SaveBitmap ResizedBMP
			else
			ResizedBMP
		),
		/*@<BitMap>*/ fn CreateBitmap /*@<Point2>*/ Size:[8, 8] /*@<Color>*/ BackColor:Red /*@<String>*/ FilePath:undefined = (
			/*@<GUIDE>
				Creates the bitmap with given unnecessary parameters "Size"(Default's [8, 8]) and "BackColor"(Default's White).
				Saves the bitmap to the path from "FilePath" parameter if it's defined, otherwise by the following formula:
					<Shared core resource cache path>/R-G-B-A_WidthxHeight.png
				returns the BitMap, or "undefined" if saving\opening failed.
			*/
			local	Width = Size.x,
			Height = Size.y
			if FilePath == undefined then (
				local	SS = ( StringStream "" )
				Format "%%-%-%-%_%x%.png" \
				GIMS.Shared.ResourceCachePath \
				( BackColor.R as integer ) \
				( BackColor.G as integer ) \
				( BackColor.B as integer ) \
				( BackColor.A as integer ) \
				( Width as integer ) \
				( Height as integer ) \
				To:SS
				FilePath = ( SS as string )
				Free SS
			)
			SaveBitMap ( Bitmap Width Height FileName:FilePath Color:BackColor )
		),
		/*@<BitMap>*/ fn GetImage /*@<ImgTag>*/ Item /*@<Name>*/ Action /*@<Name | String>*/ tIcon /*@<Point2>*/ Size:[26, 26] = (
			/*@<GUIDE>
				Creates the value "Tag" of ((tIcon as string + Action as string + Size as string) as name).
				Searches (Images)[1] array for an entry of "Tag" value, storing its number in "BitmapID" value.
				If found, returns the BitMap from Images[2][BitmapID].
				Otherwise:
				-Searches for a file ((BitmapPath) + tIcon as string + "_" + Action as string + ".png").
				-If not found, creates it in size of (Size) argument with a Red square inside. Returns it.
				-If found - opens it. If the file BitMap size's different - resizes it. Adds "Tag" value to (Images)[1], and the resulting BitMap to (Images)[2]. Returns the resulting BitMap.
			*/
			local	Tag = ( Append ( ( tIcon as String ) + ( Action as String ) ) ( Size as String ) ),
			ImageName = ( Append ( ( tIcon as string ) + ( NameSeparator as String ) ) ( Action as string ) ),
			Tags = Images[1],
			BitmapID = ( FindItem Tags Tag ),
			Result
			if BitmapID == 0 then (
				local	FilePath = ( Append ( ( BitmapPath as String ) + ( ImageName as String ) ) ( ImageExt as String ) )
				if ( DoesFileExist FilePath ) then (
					Result = ( OpenBitmap FilePath )
					local	SX = Size.x,
					SY = Size.y
					if
					Result.Width != SX or
					Result.Height != SY
					then (
						Result = ( ResizeBitmap Result Size )
						Item.Width = SX
						Item.Height = SY
					)
				) else
				Result = ( CreateBitmap Size:Size FilePath:FilePath BackColor:Red )
				Append Tags Tag
				Append Images[2] Result
			) else
			Result = Images[2][BitmapID]
			Result
		),
		/*@<BitMap | Undefined>*/ fn ImageControl /*@<ImgTag>*/ Item /*@<Name>*/ Action /*@<Name | String>*/ tIcon /*@<Point2>*/ Size:[26, 26] = (
			/*@<GUIDE>
				Sets (Item).Enabled property to true if (Action) is #Enable. Otherwise, to false.
				If (Action) is #Null, sets (Item).BitMap to undefined. Otherwise, to the result of calling (GetImage) function with all the same arguments.
			
				Returns (Item).BitMap
			*/
			Item.Enabled = (
				if Action == #Enable then
				true
				else
				false
			)
			Item.BitMap = (
				if Action != #Null then
				GetImage Item Action tIcon Size:Size
			)
		),
		fn Check = (
			if not Colour.Check() then
			throw "\n\nCan't load colors! Please, update your .NET framework and restart 3Ds MAX"
			if not Font.Check() then
			throw "\n\nCan't load fonts! Please, install these:\n\nSegoe UI\nSegoe UI Light\nSegoe UI SemiBold\n\nand restart 3Ds MAX"
			true
		),
		fn Init GIMS = (
			try (
				local	SetLifetimeController = GIMS.SetLifetimeController
				BitmapPath = ( GIMS.ScriptPath + "GIMS_GUI\\" )
				ScrollOrientation = ( DotNETClass "System.Windows.Forms.ScrollOrientation" )
				SetLifetimeController ScrollOrientation #MXS
				Align = ( DotNETClass "System.Drawing.ContentAlignment" )
				SetLifetimeController Align #MXS
				local	SDC = ( DotNETClass "System.Drawing.Color" )
				Colour.SDC = SDC
				SetLifetimeController Colour.SDC #MXS
				Colour.CBlack = SDC.Black
				Colour.CWhite = SDC.Snow
				Colour.CGray = SDC.SlateGray
				Colour.Theme = SDC.SteelBlue
				local	AccentColor = SDC.DodgerBlue
				Colour.Accent = AccentColor
				Colour.Warning = SDC.Orange
				Colour.Transparent = SDC.Black ;
				Colour.Info = SDC.Green
				local	FontFamily = ( DotNETClass "System.Drawing.FontFamily" ),
				Fonts = #(
					( "Segoe UI" as name ),
					( "Segoe UI Light" as name ),
					( "Segoe UI SemiBold" as name )
				)
				SetLifetimeController FontFamily #MXS
				for TempFont in FontFamily.Families do (
					case ( FindItem Fonts ( TempFont.Name as name ) ) of (
						1: (
							Font.Tip.Regular = ( DotNETObject "System.Drawing.Font" TempFont 9 )
							SetLifetimeController Font.Tip.Regular #MXS
							Font.Body.Regular = ( DotNETObject "System.Drawing.Font" TempFont 11 )
							SetLifetimeController Font.Body.Regular #MXS
							Font.SubHeader.Regular = ( DotNETObject "System.Drawing.Font" TempFont 20 )
							SetLifetimeController Font.SubHeader.Regular #MXS
						)
						2: (
							Font.Header = ( DotNETObject "System.Drawing.Font" TempFont 28 )
							SetLifetimeController Font.Header #MXS
							Font.SubHeader.Light = ( DotNETObject "System.Drawing.Font" TempFont 20 )
							SetLifetimeController Font.SubHeader.Light #MXS
						)
						3: (
							Font.Body.SemiBold = ( DotNETObject "System.Drawing.Font" TempFont 11 )
							SetLifetimeController Font.Body.SemiBold #MXS
							Font.Tip.SemiBold = ( DotNETObject "System.Drawing.Font" TempFont 9 )
							SetLifetimeController Font.Tip.SemiBold #MXS
						)
					)
				)
			) catch (
				messageBox ( "Line: 661 - Exception: " + GetCurrentException() ) title:"GIMS Error:" beep:true
			)
			true
		)
	)

	global	Cores = #(
		( SharedCore ServerURL:undefined tag:"Shared" name:"Shared" BasePath:undefined FilesPath:undefined BackupPath:undefined DownloadPath:undefined CachePath:undefined ResourceCachePath:undefined Core:undefined Rules:undefined Loaded:false WindowLayouts:#( ) IsUpdateDeclined:false DevInfoPropList:#( #tag, #ServerURL, #BasePath, #FilesPath, #CachePath, #ResourceCachePath, #DownloadPath, #BackupPath, #Core, #Rules, #RussianSupport, #IntlSupport, #Loaded, #WindowLayouts, #init, #Start ) ),
		( GameCore tag:"V" name:"GTA V" ServerURL:undefined BasePath:undefined FilesPath:undefined BackupPath:undefined DownloadPath:undefined CachePath:undefined ResourceCachePath:undefined Core:undefined Rules:undefined Installed:undefined Loaded:undefined WindowLayouts:#( ) IsUpdateDeclined:false DevInfoPropList:#( #tag, #name, #ServerURL, #BasePath, #FilesPath, #CachePath, #ResourceCachePath, #DownloadPath, #BackupPath, #Core, #Rules, #RussianSupport, #IntlSupport, #Installed, #Loaded, #WindowLayouts, #Install, #init , #start, #UnInstall ) )
	),
	SharedCoreID = 0

	local	CoreCount = Cores.Count
	for CoreID = CoreCount to 1 by -1 while SharedCoreID == 0 where ( Cores[CoreID].Tag as name ) == #Shared do
	SharedCoreID = CoreID
	if SharedCoreID == 1 then (
		local	CoreTags = #( )
		for i = CoreCount to 1 by -1 do
		CoreTags[i] = Cores[i].Tag
		local	CoreTagsAsFields = "",
		CoreTagsAsNames = "",
		CoreTagsAsArrayEntries = "",
		CoreTagsAsFieldInits = "",
		HeaderY = 5,
		ButtonsY = 37,
		GUIInits = ( StringStream "" ),
		CommaChar = ",",
		GridChar = "#",
		RightSquareBracket = "]",
		DoubleDotChar = ":",
		SpaceChar = " ",
		CoresIDStart = "Cores[",
		ControlSpace = 15,
		GUIInitsFormat = ( "
				GIMS.%.Init GIMS
			"		),
		CoreCount = CoreTags.Count
		for CoreID = 1 to CoreCount do (
			local	CoreIDString = ( CoreID as string )
			Append CoreTagsAsArrayEntries CoresIDStart
			Append CoreTagsAsArrayEntries CoreIDString
			Append CoreTagsAsArrayEntries RightSquareBracket
			if CoreID != CoreCount then
			Append CoreTagsAsArrayEntries CommaChar
			if CoreID != SharedCoreID then (
				local	CoreTag = CoreTags[CoreID],
				TempVal = ( CoreTag + CommaChar )
				Append CoreTagsAsFields TempVal
				Append CoreTagsAsNames ( GridChar + TempVal )
				Append CoreTagsAsFieldInits CoreTag
				Append CoreTagsAsFieldInits DoubleDotChar
				Append CoreTagsAsFieldInits CoresIDStart
				Append CoreTagsAsFieldInits CoreIDString
				Append CoreTagsAsFieldInits RightSquareBracket
				Append CoreTagsAsFieldInits SpaceChar
				Format GUIInitsFormat \
				CoreTag \
				To:GUIInits
				HeaderY += 64
				ButtonsY += 64
			)
		)
		local	Height = ( ButtonsY - 25 ),
		CompileSet = ( StringStream "" )
		Format ( "
				struct GIMSstr (
					Version = %,
					LocalApplicationPath, RoamingApplicationPath, CommonApplicationPath,
					ScriptPath = startupPath,
					GIMSPath,
					Extension,
					CoreLoader,
					Cores,
					Shared, Core,
					%
					CurrentGame,
					CoreFile = \"00_Core\",
					ConfigFile = \"System.cfg\",
					CacheConfigFile = \"Cache.cfg\",
					FilesDir = \"Files\\\\\",
					BackupDir = \"Backup\\\\\",
					CacheDir = \"Cache\\\\\",
					ResourceCacheDir = \"Resources\\\\\",
					DownloadDir = \"Download\\\\\",
					ServerURL = \"http://gims.openiv.com/downloads/GIMS/\",
					GUI = (strGUI()),
					Languages = #(),
					LangID = 1, 
					CanExec = true,
					IsDevBuild = true,
					SupportsLifetimeControl = false,
					
					IsWorkerBusy = false,
					WorkerArg,
					ProcessPostedMessages,
					
					DevInfoPropList = #(
						#Version,
						#ServerURL,
						#LocalApplicationPath,
						#CommonApplicationPath,
						#RoamingApplicationPath,
						#GIMSPath,
						#Extension,
						#CoreFile,
						#ConfigFile,
						#CacheConfigFile,
						#FilesDir,
						#BackupDir,
						#CacheDir,
						#ResourceCacheDir,
						#DownloadDir,
						#IsDevBuild,
						#Languages,
						#LangID,
						#SupportsLifetimeControl,
						#CanExec,
						#IsWorkerBusy,
						#WorkerArg,
						#GUI,
						#Shared,
						#Core,
						%
						#CurrentGame,
						#ProcessPostedMessages,
						#DoAsyncWaiting,
						#Download,
						#Init,
						#Check,
						#Load,
						#SetLifetimeController
					),
					/*@<VOID>*/ fn SetLifetimeController /*@<DotNETObject | DotNETClass>*/ Obj /*@<Name>*/ Handler = (
						/*@<GUIDE>
							Obj - DotNET object or class to control.
							Handler - #MXS or #MXS.
						
							Sets (Obj) lifetime controller to MAXScript or DotNET.
						*/
						if SupportsLifetimeControl then
							DotNET.SetLifetimeControl Obj Handler
					),
					fn CheckConnection args = (
						try (
							local	arr = GIMS.WorkerArg	--args.Argument
							if not (Internet.CheckConnection URL:arr[2] Force:true) then
								arr[1].CancelAsync()
							GIMS.IsWorkerBusy = false
						) catch (
							GIMS.IsWorkerBusy = false
							messageBox ( \"Line: 811 - Internet connection check error: Exception: \" + GetCurrentException() ) title:\"GIMS Error:\" beep:true
						)
						OK
					),
					fn DoWaitAsync Task arg Timeout:0 = (
						CanExec = false
						local	Worker = (DotNETObject \"System.ComponentModel.BackGroundWorker\")
						SetLifetimeController Worker #MXS
						Worker.WorkerSupportsCancellation = true
						DOTNet.AddEventHandler Worker \"DoWork\" Task
						local	HaveTimeout = false,
								TimeStart
						IsWorkerBusy = true
						WorkerArg = #(Worker, arg)
						Worker.RunWorkerAsync()	-- #(Worker, arg)
						if Timeout != 0 then (
							HaveTimeout = true
							TimeStart = (TimeStamp())
						)
						local	CancellationPending = false
						while IsWorkerBusy do (
							CancellationPending = Worker.CancellationPending
							if HaveTimeout then (
								local	CurTime = (TimeStamp())
								if CurTime < TimeStart then
									TimeStart = CurTime
								else (
									if (CurTime - TimeStart) > Timeout then
										CancellationPending = true
								)
							)
							if CancellationPending then (
								Worker.CancelAsync()
								IsWorkerBusy = false
							)
							ProcessPostedMessages()
						)
						CanExec = true
						(not CancellationPending)
					),
					/*@<Boolean>*/ fn Download /*@<String[]>*/ FileList /*@<String>*/ Location /*@<Boolean>*/ ShowGUI Timeout:5000 = (
						/*@<GUIDE>
							Downloads (FileList) URLs to (Location) directory.
							(ShowGUI) argument affects process visibility.
							
							Returns the downloading result.
						*/
						--Print #FnDownload	--<TODO> remove, debug--<TODO> remove, debug
						--Print #FileList	--<TODO> remove, debug
						--Print FileList	--<TODO> remove, debug
						if FileList.Count != 0 then (
							local	Result = true
							if (DoWaitAsync CheckConnection FileList[1] Timeout:Timeout) then (
								--Print #ConnectedAndDownloaded	--<TODO> remove, debug
								local	hash = (TimeStamp()),
										DownloadUrlToDisk = DragAndDrop.DownloadUrlToDisk
								for DownFile in FileList while Result do (
									local	TargetFile = (Location + (FileNameFromPath DownFile))
									if
										(not (DoesFileExist TargetFile)) and (
											(not (DownloadUrlToDisk (DownFile + \"?is=\" + (hash as String)) TargetFile 0)) or
											(not (DoesFileExist TargetFile))
										)
									then
										Result = false 
								)
							) else
								Result = false
							if not Result then (
								--Print #NotConnectedOrDownloaded	--<TODO> remove, debug
								for DownFile in FileList do
									DeleteFile (Location + (FileNameFromPath DownFile))
							)
							Result
						) else
							true
					),
					
					fn Load = (
						/* Sets MXS (DragAndDrop.GlobalEnableDragAndDrop) to true.
							Adds the (Extension) to the (CoreFile) file name.
							Returns execution result in boolean.
						*/
						local Result = true
						try (
							DragAndDrop.GlobalEnableDragAndDrop true
							EscapeEnable = False
							Extension = \".ms\"
							IsDevBuild = true
							local	HookFile = (Append ScriptsPath \"PreloadGIMS.ms\")
							if not (DoesFileExist HookFile) then
								HookFile = (Append ScriptsPath \"PreloadGIMS.ms\")
							if (DoesFileExist HookFile) then
								FileIn HookFile Quiet:true
							Append CoreFile Extension
						) catch (
							messageBox ( \"Line: 912 - Exception: \" + GetCurrentException() ) title:\"GIMS Error:\" beep:true
							Result = false
						)
						Result
					),

					fn Check = (
						GUI.Check()
					),

					fn Init = (
						try (
							try (
								DotNET.SetLifetimeControl
								SupportsLifetimeControl = true
							) catch ()
							ProcessPostedMessages = (
								try
									Windows.ProcessPostedMessages
								catch
									(DotNETClass \"Application\").DoEvents
							)
							local SysEnv = (DotNETClass \"System.Environment\"),
							SpcFolder = (DotNETClass \"System.Environment+SpecialFolder\")
							LocalApplicationPath = (SysEnv.GetFolderPath SpcFolder.LocalApplicationData)
							RoamingApplicationPath = (SysEnv.GetFolderPath SpcFolder.ApplicationData)
							CommonApplicationPath = (SysEnv.GetFolderPath SpcFolder.CommonApplicationData)
							if LocalApplicationPath.Count == 0 then
								LocalApplicationPath = CommonApplicationPath
							if RoamingApplicationPath.Count == 0 then
								RoamingApplicationPath = CommonApplicationPath
							if
								LocalApplicationPath.Count == 0 or
								RoamingApplicationPath.Count == 0 or
								CommonApplicationPath.Count == 0
							then
								throw \"Can't find the application data folders!\"
							Append LocalApplicationPath \"\\\\\"
							Append RoamingApplicationPath \"\\\\\"
							Append CommonApplicationPath \"\\\\\"
							GIMSPath = (LocalApplicationPath + \"\\GIMS\\\\\")
						) catch (
							messageBox ( \"Line: 955 - Exception: \" + GetCurrentException() ) title:\"GIMS Error:\" beep:true
							false
						)
						true
					)
				)
			GIMS = (
				GIMSstr \\
				Cores:#(%) \\
				Shared:Cores[1] \\
				%\\
			)
			if (
				GIMS.Init() and
				GIMS.GUI.Init GIMS
			) then (
				if GIMS.Load() then (
					try ( GIMS.Shared.Init GIMS ) catch ( messageBox ( \"Line 894 - Shared Core not initialized. Exception: \" + GetCurrentException() ) title:\"GIMS Error:\" ) beep:true
					try ( GIMS.V.Init GIMS ) catch ( messageBox ( \"Line 895 - GTA V Core not initialized. Exception: \" + GetCurrentException() ) title:\"GIMS Error:\" ) beep:true
					%
					local SharedStartResult = (GIMS.Shared.Start GIMS.Shared)
					if SharedStartResult == true then (
						-- sleep 60
						try ( GIMS.V.Start GIMS.V ) catch ( messageBox ( \"Line 954 - GTA V Core not started. Exception: \" + GetCurrentException() ) title:\"GIMS Error:\" ) beep:true
					)
				)
			)
			GIMSstr = undefined
		"		) \
		GIMSVersion \
		CoreTagsAsFields \
		CoreTagsAsNames \
		CoreTagsAsArrayEntries \
		CoreTagsAsFieldInits \
		Height \
		( GUIInits as string ) \
		To:CompileSet
		Execute ( CompileSet as string )
		Free CompileSet
		Free GUIInits
	) else (
		messageBox ( "Line: 1060 - Can't find the Shared core initialization." ) title:"GIMS Error:" beep:true
	)
) else (
	messageBox ( "Line: 1066 - Install AvGuard Extensions for 3D MAX." ) title:"GIMS Error:" beep:true
)
OK
endTime = timeStamp()
print ( "GIMS took " + ( ( ( endTime - startTime ) / 1000.0 ) as string ) + " seconds." )