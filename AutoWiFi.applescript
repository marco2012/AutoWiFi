-- Auto log in to Vodafone-Wifi Network using Google Chrome
-- Created by Marco2012
-- Tested on MacOS 10.14 Mojave
-- Inspired by https://apple.stackexchange.com/a/338596/63894

global wifi_name, EMAIL_VODAFONE, PASSWORD_VODAFONE

set EMAIL_VODAFONE to "INSERT_YOUR_EMAIL"
set PASSWORD_VODAFONE to "INSERT_YOUR_PASSWORD"

if firstTimeRun() then
	writeConfigFile()
	disableCaptiveNetworkWindow()
	set chrome_installed to existsGoogleChrome()
else
	set chrome_installed to true --assume chrome installed to reduce execution time
end if

set wifi_name to do shell script "/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk '/ SSID: / {print $2}'"

if chrome_installed then
	if wifi_name is "Vodafone-WiFi" then
		startLoginProcess()
	else
		display notification "I'm trying to connect to a supported network" with title "Connection in progress..." sound name "Pop"
		connectoToWiFi()
	end if
else
	display alert wifi_name message "You must install Google Chrome in order to use this script" buttons {"Dismiss", "Donwload Chrome"} default button "Download Chrome"
	if the button returned of the result is "Download Chrome" then open location "https://www.google.com/chrome/"
end if


-- HELPER FUNCTIONS

--main method to autocomplete login
on startLoginProcess()
	try
		tell application "Google Chrome"
			activate
			
			open location "http://captive.apple.com/hotspot-detect.html"
			--wait for page to load	
			repeat until (loading of active tab of window 1 is false)
			end repeat
			
			tell active tab of window 1
				execute javascript "document.getElementById('userFake').value = '" & EMAIL_VODAFONE & "' "
				execute javascript "document.getElementById('password').value ='" & PASSWORD_VODAFONE & "' "
				execute javascript "document.getElementById('login').click()"
			end tell
			
		end tell
		display notification "Please wait about 30 seconds." with title wifi_name subtitle "Connection in progress..." sound name "Pop"
	on error
		display notification "Please enter your password" with title "An error occurred..." subtitle "Clearing DNS cache..." sound name "Sosumi"
		--clear DNS cache
		do shell script "killall -HUP mDNSResponder" with administrator privileges
	end try
end startLoginProcess


--connects to wifi if available
on connectoToWiFi()
	set available_wifi_networks to paragraphs 2 thru -1 of (do shell script "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | sed -nE 's/[ ]*(.*) [a-z0-9]{2}:[a-z0-9]{2}:.+/\\1/p'")
	repeat with anItem in available_wifi_networks
		if "Vodafone-WiFi" contains anItem then --connect to wifi
			set output to do shell script "networksetup -setairportnetwork en0 Vodafone-WiFi"
			if output contains "Could not find network" then
				display notification "There was an error joining supported network." with title "WiFi not available." sound name "Sosumi"
				return false
			else
				startLoginProcess()
				return true
			end if
		else
			display notification "There are no supported networks in your area." with title "WiFi not available." sound name "Sosumi"
			return false
		end if
	end repeat
end connectoToWiFi


-- disable captive network if enabled https://apple.stackexchange.com/a/140843/63894
on disableCaptiveNetworkWindow()
	set captive_network to do shell script "defaults read /Library/Preferences/SystemConfiguration/com.apple.captive.control Active"
	if captive_network is equal to "1" then
		do shell script "defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -boolean false" with administrator privileges
	end if
end disableCaptiveNetworkWindow


--check if chrome is installed
on existsGoogleChrome()
	set chrome_installed to false
	try
		do shell script " osascript -e 'exists application \"Google Chrome\"' "
		set chrome_installed to true
	end try
	return chrome_installed
end existsGoogleChrome


on writeConfigFile() --https://apple.stackexchange.com/a/321078/63894
	set theFile to (POSIX path of ((path to documents folder as string) & "AutoWiFi_config.txt"))
	set theText to "This is a configuration file for " & name of (info for (path to me)) & ". The script was run for the first time on " & (current date) as string
	try
		set writeToFile to open for access theFile with write permission
		write theText & linefeed to writeToFile as text starting at eof
		close access theFile
	on error errMsg number errNum
		close access theFile
		set writeToFile to open for access theFile with write permission
		write theText & linefeed to writeToFile starting at eof
		close access theFile
	end try
	do shell script "chflags hidden " & theFile
end writeConfigFile


on firstTimeRun()
	set theFile to (POSIX path of ((path to documents folder as string) & "AutoWiFi_config.txt"))
	tell application "System Events"
		if exists file theFile then
			return false
		else
			return true
		end if
	end tell
end firstTimeRun
