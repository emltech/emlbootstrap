#!/bin/bash
declare -xr osx_vers=$(sw_vers -productVersion | awk -F. '{print $2}')
declare -xr sw_vers=$(sw_vers -productVersion)

intro() {
  cat <<- EOF
  EML BOOTSTRAP INTRO
  ===================
  This is the new install script for the English Media Lab.
  It will do the following tasks for you:

  1. Install xcode command line tools needed for Homebrew & Cask
  2. Install and set up Homebrew and Caskroom
  3. Set up PubkeyAuthentication in sshd_config and install SSH public key.
  4. Create Student, FilmTech, and Instructor as Standard Users. Be sure to have the standard passwords ready.
  5. Change Dock settings for all users to make it pretty the way we like it.

  This script needs to be run as EML Admin. It will make a basic minimum provision of the computer for you so that it is
  ready for Ansible management from the EML Tech machine.

  You will need to (really should) reboot after this script is finished.

EOF
}

install_xcode(){
#this whole thing from osxc & https://github.com/timsutton/osx-vm-templates/blob/master/scripts/xcode-cli-tools.sh

  dev_tools(){
    if [ "$osx_vers" -ge 9 ]; then
      # create the placeholder file that's checked by the CLI updates .dist in Apple's SUS catalog
      /usr/bin/touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      # find the product id with "Developer" in the name
      prodid=$(/usr/sbin/softwareupdate -l | awk '/Developer/{print x};{x=$0}' | awk '{print $2}')
      # install it (amazingly, it won't find the update if we put the update ID in double-quotes)
      /usr/sbin/softwareupdate -i $prodid -v
      # on 10.7/10.8, we'd instead download from public download URLs, which can be found in
      # the dvtdownloadableindex:
      # https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
    else
      [ "$osx_vers" -eq 7 ] && dmgurl=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
      [ "$osx_vers" -eq 8 ] && dmgurl=http://devimages.apple.com/downloads/xcode/command_line_tools_for_osx_mountain_lion_april_2014.dmg
      toolspath="/tmp/clitools.dmg"
      /usr/bin/curl "$dmgurl" -o "$toolspath"
      tmpmount=$(/usr/bin/mktemp -d /tmp/clitools.xxxx)
      /usr/bin/hdiutil attach "$toolspath" -mountpoint "$tmpmount"
      /usr/sbin/installer -pkg "$(find $tmpmount -name '*.mpkg')" -target /
      /usr/bin/hdiutil detach "$tmpmount"
      /bin/rm -rf "$tmpmount"
      /bin/rm "$toolspath"
    fi
  }

  # Build array of most probable receipts from cli tools for current & past OS versions, partially from
  # https://github.com/homebrew/homebrew/blob/208f963cf2/library/homebrew/os/mac/xcode.rb#l147-l150
  declare -ra bundle_ids=('com.apple.pkg.DeveloperToolsCLI' \
  'com.apple.pkg.DeveloperToolsCLILeo' 'com.apple.pkg.CLTools_Executables' \
  'com.apple.pkg.XcodeMAS_iOSSDK_7_0')
  # set flag for the presence of a cli tools receipt
  declare -i xcode_cli=0
  # iterate over array, break out and skip install if we get a zero return code
  for id in ${bundle_ids[@]}; do
    /usr/sbin/pkgutil --pkg-info=$id > /dev/null 2>&1
    if [[ $? == 0 ]]; then
      echo "Found "$id", Xcode Developer CLI Tools install not needed"
      echo ""
      echo ""
      ((xcode_cli++))
      break
    fi
  done

  if [[ $xcode_cli -ne 1 ]]; then
    echo "Xcode Tools installation"
    echo "------------------------"
    echo ""
    echo "Please wait while xcode is installed"
    dev_tools
    if [[ $? -ne 0 ]]; then
      echo "Xcode installation failed" && exit 1
    fi
    echo ""
    echo ""
  fi
}

install_homebrew() {
  declare -r brew_path="export PATH=/usr/local/bin:$PATH"
  echo "Installing Homebrew. Follow the prompts."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  if [[ $(grep -c "$brew_path" ~/.bash_profile) -eq 0 ]]; then
    echo "Fixing Brew path"
    echo "$brew_path" >> ~/.bash_profile
  fi
}

install_cask() {
  declare -r cask_appdir="export HOMEBREW_CASK_OPTS=\"--appdir=/Applications\""
  echo "Installing Cask"
  /usr/local/bin/brew install caskroom/cask/brew-cask
  #fix brew path and make sure Cask symlinks to /Applications rather than ~/Applications.
  #This way we can ensure the all gui programs are accessible for all users, including our standard accounts.
  if [[ $(grep -c "$cask_appdir" ~/.bash_profile) -eq 0 ]]; then
    echo "Changing default Cask symlink location to /Applications"
    echo "$cask_appdir" >> ~/.bash_profile
  fi
}

configure_schedule_and_netwake() {
  #set power and sleep schedule, set autorestart after power failure, set wake on network/modem access
  sudo /usr/bin/pmset repeat wakeorpoweron MTWRF 08:59:00 shutdown MTWRFSU 22:00:00
  sudo /usr/bin/pmset displaysleep 240 disksleep 240 sleep 480 womp 1 autorestart 1 networkoversleep 1 ring 1
  sudo /usr/sbin/systemsetup -setwakeonnetworkaccess on
}

configure_sleep_security() {
  /usr/bin/defaults write com.apple.screensaver askForPassword 1
  /usr/bin/defaults write com.apple.screensaver askForPasswordDelay -int 5
}

setup_ARD() {
  printf "%s\n" "Setting up ARD access for "$USER"."
  #Turn on Remote Desktop control with full access for Admin account only.
  sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate \
  -configure \
  -access -on \
  -users "$USER" \
  -privs -all \
  -restart -agent
}

# SSH SET UP
# NEXT THREE COMMANDS
# 1. Use systemsetup to turn on "Remote Login" in System Preferences
# 2. Configure SSHD to use PublicKeys but not allow Root Login.
# 3. Install public key from github.

setup_SSHlogin() {
  printf "\n%s\n" "Turning on SSH login in System Preferences."
  sudo /usr/sbin/systemsetup -setremotelogin On
  sudo /usr/sbin/systemsetup -getremotelogin
  #turn on firewall but allow ssh, ard, etc.
  sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
}

configure_SSHD() {
  declare -r bakdate=$(/bin/date -j +%d.%m.%y)
  echo "Editing /etc/sshd_config: LogLevel, PermitRootLogin, PubkeyAuthentication, PasswordAuthentication. Need root permissions."
  sudo /usr/bin/sed -i."$bakdate".bak \
  -e 's/^#LogLevel INFO/LogLevel INFO/' \
  -e 's/^#PermitRootLogin .*/PermitRootLogin no/' \
  -e 's/^#PubkeyAuthentication .*/PubkeyAuthentication yes/' \
  -e 's/^#PasswordAuthentication .*/PasswordAuthentication no/' \
  /etc/sshd_config
}

install_pubkey() {
  echo "Installing public key from Github to ~/.ssh/authorized_keys"
  #get key from github. my own private hack...
  declare -r publickey=$(curl -fSsl https://api.github.com/users/emltech/keys | grep "key" | cut -d " " -f 6,7 | sed 's/"//g')
  #paranoia for updates. check for .ssh dir + authorized keys
  if [ ! -d ~/.ssh ]; then
    if [ ! -f ~/.ssh/authorized_keys ]; then
      echo "Making .ssh directory"
      mkdir ~/.ssh
      touch ~/.ssh/authorized_keys
      chmod 600 ~/.ssh/authorized_keys
    fi
  fi
  #check if key in file, once made or found above
  if [[ $(grep -c "$publickey" ~/.ssh/authorized_keys) -eq 0 ]]; then
    echo "$publickey" >> ~/.ssh/authorized_keys
  else
    echo "Public key is already installed. Skipping!"
  fi
}

#DONE SSH

misc_defaults() {
# Disable Resume system-wide
sudo defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
# Expand save panel by default
sudo defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
sudo defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
# Disable local Time Machine backups
hash tmutil &> /dev/null && sudo tmutil disablelocal
}

create_users() {
  #Check for highest UniqueID and for Staff GroupID for Standard Users.
  declare -ir lastid=$(/usr/bin/dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
  #Staff GroupID is almost certainly 20 but why guess?
  declare -ir staffgid=$(/usr/bin/dscl . -read /Groups/staff PrimaryGroupID | cut -d " " -f 2)
  #Array of EML default users (besides EML Admin)
  declare -ar defusers=("student" "filmtech" "instructor")
  #DON'T escape spaces in paths for dscl!
  #Admin picture is Whiterose.tif, student is Golf.tif, Filmtech is Medal.tif, Instructor is Red Rose.tif
  declare -ar userpictures=("/Library/User Pictures/Sports/Golf.tif" "/Library/User Pictures/Fun/Medal.tif" "/Library/User Pictures/Flowers/Red Rose.tif")

  #createuser wants $1 USERNAME, $2 UNIQUEID, $3 USERPICTURE
  create_user() {
    local userpath=/Users/"$1"
    #Convert first letter of username to Uppercase. This is just for Real Name key, which is what shows up on login screen. (eg. Instructor)
    local realnameupper=$(echo "$1" | /usr/bin/perl -pe 's/\S+/\u$&/g')
    sudo /usr/bin/dscl . -create "$userpath"
    sudo /usr/bin/dscl . -create "$userpath" UserShell /bin/bash
    sudo /usr/bin/dscl . -create "$userpath" RealName "$realnameupper"
    sudo /usr/bin/dscl . -create "$userpath" UniqueID "$2"
    sudo /usr/bin/dscl . -create "$userpath" PrimaryGroupID "$staffgid"
    sudo /usr/bin/dscl . -create "$userpath" NFSHomeDirectory "$userpath"
    sudo /usr/bin/dscl . -create "$userpath" hint "Ask EML Technician"
    sudo /usr/bin/dscl . -create "$userpath" Picture "$3"
    sudo passwd "$1"
    sudo mkdir "$userpath"
    printf "%s\n" "Creating ~/ at "\"$userpath\"" with the following items:"
    sudo cp -Rv /System/Library/User\ Template/English.lproj/ "$userpath"
    sudo chown -R "$1":staff "$userpath"
    printf "%s\n\n" "Finished creating account "\"$1\"" at "\"$userpath\""."
  }

  #Turn off icloud set up on first login. We don't want to have to personally log into each machine to go through the intro...
  disable_icloud_setup() {
    local user="$1"
    local userpath=/Users/"$user"
    #defaults write will make this file properly for us. No reason to check if it exists.
    sudo defaults write "$userpath"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
    sudo defaults write "$userpath"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
    sudo defaults write "$userpath"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
    sudo chown "$user" "$userpath"/Library/Preferences/com.apple.SetupAssistant.plist
  }

  for i in "${!defusers[@]}"
  do
    local index="$i"
    local uniqueid="$((lastid + index + 1))" #+1 to not overwrite the LASTID on the 0 index of the array.
    local username="${defusers[$i]}"
    local userpicture="${userpictures[$i]}"
    #Don't create Student and Instructor accounts if they already exist. Warning! We only check for
    #Users in standard OSX location /Users/!
    if [[ $(/usr/bin/dscl . list /Users | grep -ci "$username") -eq 0 ]]; then
      printf "\n%s\n" "User "\"$username\"" does not currently exist. making "\"$username\"" account now!"
      create_user "$username" "$uniqueid" "$userpicture"
      disable_icloud_setup "$username"
      else
      printf "%s\n\n" "User "\"$username\"" already exists. Cannot, should not, and will not overwrite. Skipping!"
    fi
  done

}

custom_screensaver() {
  sudo mv /System/Library/Screen\ Savers/Arabesque.qtz /System/Library/Screen\ Savers/backup.arabesque.qtz
  sudo cp ./eml_screensaver.qtz /System/Library/Screen\ Savers/
  sudo mv /System/Library/Screen\ Savers/eml_screensaver.qtz /System/Library/Screen\ Savers/Arabesque.qtz
  sudo chown root /System/Library/Screen\ Savers/Arabesque.qtz
  sudo chgrp wheel /System/Library/Screen\ Savers/Arabesque.qtz
  sudo chmod 644 /System/Library/Screen\ Savers/Arabesque.qtz
}

configure_login_window() {
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText \
  "Welcome to the English Media Lab. Login information is available on the white board or \
  from the EML Technician. By logging in you agree to abide by the Lab Computer Guidelines. \
  Please ask the EML Technician for any assistance."
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME False
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWOTHERUSERS_MANAGED False
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow com.apple.login.mcx.DisableAutoLoginClient True
  #set loginwindow to use screensaver we just installed
  sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 15
  sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowModulePath "/System/Library/Screen Savers/Arabesque.qtz"
  #set PolicyBanner
  sudo cp -R ./PolicyBanner.rtfd /Library/Security/
  sudo chmod -R o+rw /Library/Security/PolicyBanner.rtfd
}

main() {
    #Before we start. Check if we have admin privileges
    declare -ir in_admin="$(/usr/bin/dscl /Search read /Groups/admin GroupMembership | /usr/bin/grep -c $USER)"
    [ "$in_admin" != 1 ] \
    && printf "%s\n" "This script requires admin access, you're logged in as $USER!" \
    && exit 1

  intro
  read -p "Continue? [Press Enter]"
  install_xcode
  install_homebrew
  install_cask
  configure_schedule_and_netwake
  configure_sleep_security
  setup_ARD
  setup_SSHlogin
  configure_SSHD
  install_pubkey
# configure_dock
  misc_defaults
  create_users
  custom_screensaver
  configure_login_window

  printf "%s\n" "DONE-SO! HEY LISTEN, YOU SHOULD REBOOT THE COMPUTER NOW. REALLY."
}
main