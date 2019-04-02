-- Auto log in to Vodafone-Wifi Network using Google Chrome
-- Created by Marco2012
-- Tested on MacOS 10.14 Mojave
-- Inspired by https://apple.stackexchange.com/a/338596/63894

-- just set these variables
set user_email to "YOUR_VODAFONE_WIFI_USERNAME"
set user_password to "YOUR_VODAFONE_WIFI_PASSWORD"

-- disable captive network if enabled https://apple.stackexchange.com/a/140843/63894
set captive_network to do shell script "defaults read /Library/Preferences/SystemConfiguration/com.apple.captive.control Active"
if captive_network is equal to "1" then
do shell script "sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -boolean false"
end if

--check if chrome is installed
set chrome_installed to false
try
	do shell script " osascript -e 'exists application \"Google Chrome\"' "
	set chrome_installed to true
end try

set wifi_name to do shell script "/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk '/ SSID: / {print $2}'"

if wifi_name is "Vodafone-WiFi" and chrome_installed then
	tell application "Google Chrome"
		activate
		open location "http://captive.apple.com/hotspot-detect.html"
		
		repeat until (loading of active tab of window 1 is false) --wait for page to load	
		end repeat
		
		tell active tab of window 1
			execute javascript "document.getElementById('userFake').value = ' " & user_email & " ' "
			execute javascript "document.getElementById('password').value =' " & user_password & " ' "
			execute javascript "document.getElementById('login').click()"
		end tell
		
	end tell
	
	display alert wifi_name message "Connection in progress..." buttons {"OK"} default button "OK" giving up after 3
else if not chrome_installed then
	display alert wifi_name message "Install Google Chrome first" buttons {"OK"} default button "OK" giving up after 3
else
	display alert wifi_name message "Connect to Vodafone-Wifi first" buttons {"OK"} default button "OK" giving up after 3
end if

