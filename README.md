# rp-box86wine
Box86 and Wine on RetroPie

This repository exists to facilitate installation of Box86 and Wine on RetroPie. A pull request has already been created to merge these scripts into the main RetroPie distribution (https://github.com/RetroPie/RetroPie-Setup/pull/3285). Further development and dependencies are required. For example, a newer version of Mesa is required to play many games that require OpenGL. This repository will be kept in sync with the pull request.

To use this repository, you must be running RetroPie v4.7.7 or later, which has the ability to use external repositories script modules. This should help keep your main RetroPie scripts clean. Use the following command:

```
git clone https://github.com/GeorgeMcMullen/rp-box86wine.git /home/pi/RetroPie-Setup/ext/rp-box86wine/
```

Then while running RetroPie-Setup, you should see a new subsection in "dependencies" and "experimental" with the scripts in them. They must be run in order and will produce an error if you try to install them out of order. Launch RetroPie Setup, go to "Manage Packages" (P) and then run the scripts as follows:

- depends/mesa
- experimental/box86
- experimental/wine

# Resources
- Feedback, updated, issues can be discussed in this forum post: https://retropie.org.uk/forum/topic/28528/box86-and-wine-on-rpi4
- If you've had success with a game, or wonder what other people have been able to play, check out this forum post: https://retropie.org.uk/forum/topic/29241/the-what-works-with-box86-wine-topic-on-the-retropie-rpi4-400
- Wine App Compatibility Database: https://appdb.winehq.org/
- Box86 Compatibility List: https://github.com/ptitSeb/box86-compatibility-list/issues
- Box86 on GitHub: https://github.com/ptitSeb/box86
- Box86 on Discord: https://discord.com/invite/Fh8sjmu
