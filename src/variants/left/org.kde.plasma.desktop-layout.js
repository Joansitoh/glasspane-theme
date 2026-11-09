// Glasspane Left: start button on the left, tasks right next to it (classic style).
// Glasspane Start is a separate widget. If it is not installed (e.g. the theme was
// installed from the KDE UI only), fall back to the stock launcher so the panel still works.
var START_WIDGET = (typeof knownWidgetTypes !== "undefined" &&
                    knownWidgetTypes.indexOf("com.joansitoh.glasspane.start") >= 0)
    ? "com.joansitoh.glasspane.start" : "org.kde.plasma.kickoff";

function buildPanel(screen, floating) {
    var p = new Panel;
    p.location = "bottom";
    p.screen = screen;
    p.height = 38;
    p.addWidget(START_WIDGET);
    p.addWidget("org.kde.plasma.pager");
    var t = p.addWidget("org.kde.plasma.icontasks");
    t.currentConfigGroup = ["General"];
    t.writeConfig("iconSpacing", 1);
    p.addWidget("org.kde.plasma.marginsseparator");
    // Windows-style tray: only network, volume and battery in view; the rest behind the ^ arrow.
    var tray = p.addWidget("org.kde.plasma.systemtray");
    tray.currentConfigGroup = ["General"];
    tray.writeConfig("shownItems", "org.kde.plasma.networkmanagement,org.kde.plasma.volume,org.kde.plasma.battery");
    tray.writeConfig("hiddenItems", "org.kde.kdeconnect,org.kde.plasma.vault,org.kde.plasma.brightness,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.plasma.dwellclicker,org.kde.plasma.keyboardlayout,org.kde.plasma.printmanager,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.keyboardindicator,org.kde.plasma.weather");
    tray.writeConfig("showAllItems", "false");
    var c = p.addWidget("org.kde.plasma.digitalclock");
    c.currentConfigGroup = ["Appearance"];
    c.writeConfig("autoFontAndSize", "false");
    c.writeConfig("fontFamily", "Noto Sans");
    c.writeConfig("fontSize", "9");
    c.writeConfig("fontStyleName", "Regular");
    c.writeConfig("fontWeight", "400");
    c.writeConfig("showDate", "true");
    // Windows-style clock: HH:mm:ss with dd/MM/yyyy underneath.
    c.writeConfig("showSeconds", 2);
    c.writeConfig("use24hFormat", 2);
    c.writeConfig("dateDisplayFormat", "BelowTime");
    c.writeConfig("dateFormat", "custom");
    c.writeConfig("customDateFormat", "dd/MM/yyyy");
    p.floating = floating;
}
for (var i = 0; i < screenCount; ++i) {
    buildPanel(i, i == 0);
}
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}
