To use this application:

First, install the required dependency by running:
> flutter pub add flutter_bluetooth_serial

Add the following permissions to your Android manifest (android/app/src/main/AndroidManifest.xml):
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

For iOS, add the following to your Info.plist:
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need Bluetooth permission to connect to Arduino</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need Bluetooth permission to connect to Arduino</string>

The app will:
> Show all paired Bluetooth devices
> Allow you to connect to your Arduino
> Provide buttons to turn the LED on/off
> Allow you to specify blink count and duration

Arduino Script: 
