# fēnix 7 Pro — API compatibility

Facts below come from the SDK 9.1.0 device files (`%APPDATA%\Garmin\ConnectIQ\Devices\fenix7pro\compiler.json` and `simulator.json`). Re-check them there after SDK/device updates.

| Property | Value |
|---|---|
| Product id | `fenix7pro` (display name "fēnix® 7 Pro", part 006-B4375-00) |
| Related variant | `fenix7pronowifi` — "fēnix 7 Pro – Solar Edition (no Wi-Fi)", part 006-B4595-00 |
| Connect IQ API | 5.2.0 |
| Display | 260×260 round, MIP, 8 bits per pixel |
| Input | 5 buttons + touchscreen (tap → onSelect, swipes → page/back) |
| Launcher icon | 40×40 |
| Memory limits | watch-app 768 KB · data field 256 KB · watch face 128 KB · glance 64 KB · background 64 KB · audio content provider 512 KB |

> Which variant is your watch? Check *Settings → System → About* on the watch, or whether it has Wi-Fi. If it's the no-Wi-Fi Solar Edition, add `fenix7pronowifi` to the manifest products ("Monkey C: Edit Products") and test on that simulator profile too.

## Rules

- `minApiLevel` is `5.2.0` in `manifest.xml`. Lower it only if you add older devices, and then guard newer APIs.
- An API's docs page lists the version it was added in ("Since") — anything newer than 5.2.0 is **not available** on this watch even if it's in the SDK.
- Some APIs depend on hardware, not just API level. Guard them at runtime:

```monkeyc
if (Toybox has :SensorHistory) {
    // module exists on this device
}
if (dc has :setAntiAlias) {
    dc.setAntiAlias(true);
}
```

- To confirm a symbol exists for this device, compile: the compiler checks against the device's API surface. `<SDK>\bin\api.debug.xml` lists the full SDK API.
- Hardware facts the simulator can't prove (sensor availability while worn, GPS behaviour, battery impact, real touch/button feel) must be verified on the watch.
