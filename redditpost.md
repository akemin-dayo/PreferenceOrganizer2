**Cydia/APT Repo URL:** https://cydia.angelxwind.net/

[**Tap here to add my repo directly to Cydia!**](https://cydia.angelxwind.net/add.php)

[**Donate Using PayPal (`rei@angelxwind.net`)**](https://www.paypal.com/myaccount/transfer/send/external?recipient=rei@angelxwind.net&amount=&currencyCode=USD&payment_type=Gift) (donations are greatly appreciated, *but are not (and never will be) necessary!*)

#**Important Announcement**

Due to limited time and other personal circumstances, progress on mikoto and my other projects will be a bit slower than usual.

Next on my list is the long-overdue "iOS 8+ EA Game Fixer" (I'm bad at coming up with names... it works on non-EA games with the same bug too...)

Then afterwards, a full refactor/cleanup of JellyLock Unified. Because it needs one. *Then* I'll get to forward-porting the JellyLock iOS 5/6 features to the iOS 7/8/9 codebase.

#**Changelog ([full changelog](https://cydia.angelxwind.net/?page/net.angelxwind.jellylockunified-changelog))**

* **[3.1.1] [Misc]** Fixed a bug where preference resetting might claim to fail even if it didn't.
* **[3.1.1] [Misc]** Updated to use my public open-source [KarenPrefs](https://github.com/angelXwind/KarenPrefs) library. Also updated PreferenceOrganizer 2's usage of KarenPrefs to include colored buttons, animated exit-to-SpringBoard app close animation, and many other things I've forgotten by now.
* **[3.1.1] [Misc]** Updated to use my public open-source [KarenLocalizer](https://github.com/angelXwind/KarenLocalizer) library.
* **[3.1] [Misc]** 日本語化を追加しました
* **[3.1] [Misc]** Changed default section titles
* **[3.1] [iOS 7+]** Fixed a bug where PreferenceOrganizer 2 would sort preferences incorrectly (by one `GroupID`) if a DDI was mounted and PreferenceLoader 2.2.3+ was installed.
* **[3.1] [iOS 9, iPads only]** Worked around a crash caused by removing System Apps from the main Settings view on iPads running iOS 9(!?)
* **[3.0.4] [iOS 6+]** Fixed a bug where PreferenceOrganizer 2 would cause the "prefs:" URL scheme to behave incorrectly.
* **[3.0.3] [iOS 6]** Fixed a bug where PreferenceOrganizer 2 would sort things into the wrong categories on iOS 6.
* **[3.0] [Misc]** Added some more useful information regarding the debug logging feature
* **[3.0] [Misc]** Added KarenLocalize support (previously in mikoto and Pasithea) to PreferenceOrganizer 2
* **[3.0] [Misc]** Added a PayPal donate button (`rei@angelxwind.net`)
* **[3.0] [iOS 9]** Fixed a bug where well, PreferenceOrganizer 2 would completely fail to work at all on iOS 9 ;P
* **[3.0] [iOS 8+]** Fixed a bug where News, iBooks, Podcasts, and iTunes U would disappear.

#**Known issues**

* **[iOS 9 iPads]** The current workaround to prevent iOS 9 iPads from crashing is not a real solution, as it leaves the System Apps settings in the main view.
* **[iOS 8+]** News, iBooks, Podcasts, and iTunes U do not show in Apple Apps like they are supposed to. Instead, they are simply appended below iCloud.

#**Planned features that are still unimplemented**

* **[Misc]** 繁體中文／簡體中文的翻譯

#**Help! My device caught fire and pineapples are coming out of the Lightning port!**

If you think PreferenceOrganizer 2 made your device crash, install CrashReporter and send me an email using its app.

Otherwise, please report all other issues here in this reddit thread so others will be able to share knowledge.

Also, **please state which version of PreferenceOrganizer 2 you are using.**

#**No, like, pineapples are *literally* coming out of my Lightning port.**

Your device is now violating... *several* laws of thermodynamics. Congratulations!

#**For new users: So what *is* PreferenceOrganizer 2?**

A simple and free alternative to PreferenceFolders, compatible with iOS 6, 7, 8, and 9.

PreferenceOrganizer 2 organises your Settings app by separating your Settings app into 4 configurable categories: Apple Apps, Social Apps, Tweaks, and App Store Apps.

Uses [KarenPrefs](https://github.com/angelXwind/KarenPrefs) and [KarenLocalizer](https://github.com/angelXwind/KarenLocalizer).

All features are configurable through PreferenceOrganizer 2's preference pane in the Settings app.