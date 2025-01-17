#!/bin/bash
#variables
Citra_emuName="Citra"
Citra_emuType="$emuDeckEmuTypeAppImage"
Citra_emuPath="$HOME/Applications/citra-qt.AppImage"
Citra_releaseURL=""
Citra_configFile="$HOME/.config/citra-emu/qt-config.ini"
Citra_texturesPath="$HOME/.config/citra-emu/load/textures"

#cleanupOlderThings
Citra_finalize(){
 echo "NYI"
}

#Install
Citra_install(){
	setMSG "Installing $Citra_emuName"
	installEmuFP "${Citra_emuName}" "${Citra_emuPath}"
	curl -L https://github.com/citra-emu/citra-web/releases/download/2.0/citra-setup-linux > citra-setup-linux && chmod +x citra-setup-linux && ./citra-setup-linux --accept-licenses --confirm-command install
	rm citra-setup-linux
}

#ApplyInitialSettings
Citra_init(){
	setMSG "Initializing $Citra_emuName settings."
	#configEmuFP "${Citra_emuName}" "${Citra_emuPath}" "true"
	Citra_migrate

	Citra_setupStorage
	Citra_setEmulationFolder
	Citra_setupSaves
	#SRM_createParsers
	#Citra_addSteamInputProfile
}

#update
Citra_update(){
	setMSG "Updating $Citra_emuName settings."
	cd $HOME/.citra && ./maintenancetool update
	Citra_setupStorage
	Citra_setEmulationFolder
	Citra_setupSaves
	Citra_addSteamInputProfile
}

#ConfigurePaths
Citra_setEmulationFolder(){
	setMSG "Setting $Citra_emuName Emulation Folder"

	gameDirOpt='Paths\\gamedirs\\3\\path='
	newGameDirOpt='Paths\\gamedirs\\3\\path='"${romsPath}/n3ds"
	sed -i "/${gameDirOpt}/c\\${newGameDirOpt}" "$Citra_configFile"

	#Setup symlink for AES keys
	mkdir -p "${biosPath}/citra/"
	mkdir -p "$HOME/.local/share/citra-emu/sysdata"
	ln -sn "$HOME/.local/share/citra-emu/sysdata" "${biosPath}/citra/keys"
}

#SetupSaves
Citra_setupSaves(){
	linkToSaveFolder citra saves "$HOME/.local/share/citra-emu/sdmc"
	linkToSaveFolder citra states "$HOME/.local/share/citra-emu/states"
}


#SetupStorage
Citra_setupStorage(){

	if [ -d "${HOME}/.local/share/Steam" ]; then
		STEAMPATH="${HOME}/.local/share/Steam"
	elif [ -d "${HOME}/.steam/steam" ]; then
		STEAMPATH="${HOME}/.steam/steam"
	else
		echo "Steam install not found"
	fi

	if [[ -L "$romsPath/n3ds" && ! $(readlink -f "$romsPath/n3ds") =~ ^"$romsPath" ]] || [[ -L "$romsPath/3ds" && ! $(readlink -f "$romsPath/3ds") =~ ^"$romsPath" ]]; then
		echo "User has symlinks that don't match expected paths located under $romsPath. Aborting symlink update."
	else
		if [[ ! -e "$romsPath/3ds" && ! -e "$romsPath/n3ds" ]]; then
			mkdir -p "$romsPath/n3ds"
			ln -sfn "$romsPath/n3ds" "$romsPath/3ds"
		elif [[ -d "$romsPath/3ds" && -L "$romsPath/n3ds" ]]; then
			echo "Converting n3ds symlink to a regular directory..."
			unlink "$romsPath/n3ds"
			mv "$romsPath/3ds" "$romsPath/n3ds"
			ln -sfn "$romsPath/n3ds" "$romsPath/3ds"
			echo "3ds symlink updated to point to n3ds"
		elif [[ -d "$romsPath/3ds" && ! -e "$romsPath/n3ds" ]]; then
			echo "Creating n3ds directory and updating 3ds symlink..."
			mv "$romsPath/3ds" "$romsPath/n3ds"
			ln -sfn "$romsPath/n3ds" "$romsPath/3ds"
			echo "3ds symlink updated to point to n3ds"
		elif [[ -d "$romsPath/n3ds" && ! -e "$romsPath/3ds" ]]; then
			echo "3ds symlink not found, creating..."
			ln -sfn "$romsPath/n3ds" "$romsPath/3ds"
			echo "3ds symlink created"
		fi
	fi
	find "$STEAMPATH/userdata" -name "shortcuts.vdf" -exec sed -i "s|${romsPath}/n3ds|${romsPath}/3ds|g" {} +

	local textureLink="$(readlink -f "$Citra_texturesPath")"
	if [[ "$textureLink" != "$emulationPath/hdpacks/3ds" ]]; then
		rm -rf "$Citra_texturesPath"
		ln -s "$Citra_texturesPath" "$emulationPath/hdpacks/3ds"
	fi

	if [ ! -f "$storagePath/citra/nand" ] && [ -d "$HOME/.local/share/citra-emu/nand/" ]; then

		echo "citra nand does not exist in storagepath."
		echo -e ""
		setMSG "Moving Citra nand to the Emulation/storage folder"
		echo -e ""

		mv "$HOME/.local/share/citra-emu/nand/" $storagePath/citra/nand/
		mv "$HOME/.local/share/citra-emu/sdmc/" $storagePath/citra/sdmc/

		unlink "$HOME/.local/share/citra-emu/nand/"
		unlink "$HOME/.local/share/citra-emu/sdmc/"

		ln -ns "${storagePath}/citra/nand/" "$HOME/.local/share/citra-emu/nand/"
		ln -ns "${storagePath}/citra/sdmc/" "$HOME/.local/share/citra-emu/sdmc/"
	fi

}


#WipeSettings
Citra_wipe(){
	setMSG "Wiping $Citra_emuName config directory. (factory reset)"
	rm -rf "$HOME/.config/citra-emu"
}


#Uninstall
Citra_uninstall(){
	setMSG "Uninstalling $Citra_emuName."
	cd $HOME/.citra && ./maintenancetool purge
}

#setABXYstyle
Citra_setABXYstyle(){
		echo "NYI"
}

#Migrate
Citra_migrate(){
echo "Begin Citra Migration"
	emu="Citra"
	migrationFlag="$HOME/.config/EmuDeck/.${emu}MigrationCompleted"
	#check if we have a nomigrateflag for $emu
	if [ ! -f "$migrationFlag" ]; then
		#citra flatpak to appimage
		#From -- > to
		migrationTable=()
		migrationTable+=("$HOME/.var/app/org.citra_emu.citra/data/citra-emu" "$HOME/.local/share/citra-emu")
		migrationTable+=("$HOME/.var/app/org.citra_emu.citra/config/citra-emu" "$HOME/.config/citra-emu")

		# migrateAndLinkConfig "$emu" "$migrationTable"
	fi

	#move data from hidden folders out to these folders in case the user already put stuff here.
	origPath="$HOME/.var/app/org.citra_emu.citra/data/citra_emu/"

	Citra_setupStorage

	rsync -av "${origPath}citra/dump" "${storagePath}/citra/" && rm -rf "${origPath}citra/dump"
	rsync -av "${origPath}citra/load" "${storagePath}/citra/" && rm -rf "${origPath}citra/load"
	rsync -av "${origPath}citra/sdmc" "${storagePath}/citra/" && rm -rf "${origPath}citra/sdmc"
	rsync -av "${origPath}citra/nand" "${storagePath}/citra/" && rm -rf "${origPath}citra/nand"
	rsync -av "${origPath}citra/screenshots" "${storagePath}/citra/" && rm -rf "${origPath}citra/screenshots"
	rsync -av "${origPath}citra/tas" "${storagePath}/citra/" && rm -rf "${origPath}citra/tas"
}

#WideScreenOn
Citra_wideScreenOn(){
echo "NYI"
}

#WideScreenOff
Citra_wideScreenOff(){
echo "NYI"
}

#BezelOn
Citra_bezelOn(){
echo "NYI"
}

#BezelOff
Citra_bezelOff(){
echo "NYI"
}

#finalExec - Extra stuff
Citra_finalize(){
	echo "NYI"
}

Citra_IsInstalled(){
	if [ -e "$Citra_emuPath" ]; then
		echo "true"
	else
		isFpInstalled "citra_emu"
	fi
}

Citra_resetConfig(){
	Citra_init &>/dev/null && echo "true" || echo "false"
}

Citra_addSteamInputProfile(){
	addSteamInputCustomIcons
	#rsync -r "$EMUDECKGIT/configs/steam-input/citra_controller_config.vdf" "$HOME/.steam/steam/controller_base/templates/"
}

Citra_setResolution(){
	case $citraResolution in
		"720P") multiplier=3;;
		"1080P") multiplier=5;;
		"1440P") multiplier=6;;
		"4K") multiplier=9;;
		*) echo "Error"; return 1;;
	esac

	setConfig "resolution_factor" $multiplier "$Citra_configFile"
}