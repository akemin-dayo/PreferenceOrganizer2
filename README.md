# PreferenceOrganiser 2
###### iOS Preferences app de-cluttering tweak for iOS 14, 13, 12, 11, 10, 9, 8, 7, and 6!

## What is PreferenceOrganiser 2?

PreferenceOrganiser 2 de-clutters your Preferences app by organising your preferences into several configurable categories for ease of navigation.

Uses [KarenPrefs](https://github.com/akemin-dayo/KarenPrefs) and [KarenLocalizer](https://github.com/akemin-dayo/KarenLocalizer).

All features are configurable through PreferenceOrganizer 2's preferences.

---

## How do I install PreferenceOrganiser2 on my jailbroken iOS device?

PreferenceOrganiser2 is available from **Karen's Repo: https://cydia.akemi.ai/** ([Tap here on your device to automatically add the repo!](https://cydia.akemi.ai/add.php))

If you do not see PreferenceOrganiser2 listed in Karen's Repo, then that just means you have another repository added that is also hosting a copy of PreferenceOrganiser2 under the same package ID.

**_Please_ only ever install the official, unmodified release from Karen's Repo for your own safety!**

By installing third-party modified versions of _any tweak_ like PreferenceOrganiser2, you are putting the security and stability of your iOS device and your personal data at risk.

---

## How do I build PreferenceOrganiser2?

First, make sure you have [Theos](https://github.com/theos/theos) installed. If you don't, [please refer to the official documentation](https://github.com/theos/theos/wiki/Installation) on how to set up Theos on your operating system of choice.

Then, please set up [KarenPrefs](https://github.com/akemin-dayo/KarenPrefs#karenprefs-setup-and-usage-assuming-you-already-have-the-latest-version-of-theos) and [KarenLocalizer](https://github.com/akemin-dayo/KarenLocalizer#karenlocalizer-setup-and-usage-assuming-you-already-have-the-latest-version-of-theos) for development — instructions for doing so can be found at those links. (tl;dr: `git clone` and `make setup`).

Once you've confirmed that you have _all_ of the above, open up Terminal and run the following commands:

```
git clone https://github.com/akemin-dayo/PreferenceOrganizer2.git
cd PreferenceOrganizer2
make
make package
```

And you should have a freshly built *.deb package file of PreferenceOrganiser2!

---

## License

Licensed under the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
