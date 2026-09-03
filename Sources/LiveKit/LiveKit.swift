/*
 * Copyright 2026 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

internal import LiveKitUniFFI
internal import LiveKitWebRTC
import Foundation

/// The open source platform for real-time communication.
///
/// See [LiveKit's Online Docs](https://docs.livekit.io/) for more information.
///
/// Comments are written in [DocC](https://developer.apple.com/documentation/docc) compatible format.
/// With Xcode 13 and above you can build documentation right into your Xcode documentation viewer by chosing
/// **Product** >  **Build Documentation** from Xcode's menu.
///
/// Download the [Multiplatform SwiftUI Example](https://github.com/livekit/multiplatform-swiftui-example)
/// to try out the features.
@objcMembers
public class LiveKitSDK: NSObject, Loggable {
    override private init() {}

    @objc(sdkVersion)
    public static let version = "2.16.0"
    static let ffiVersion = buildVersion()

    fileprivate struct State {
        var logger: any Logger = OSLogger()
        var tracing: any Tracing = LoggingTracer()
        var videoPublishStartBitrateKbps: Int?
    }

    fileprivate static let state = StateSync(State())

    /// Set a custom ``Tracing`` implementation to capture operation timing.
    ///
    /// The default ``LoggingTracer`` logs completed spans at debug level.
    /// Provide a custom implementation to capture timing data
    /// programmatically (e.g., for benchmarks).
    ///
    /// - Note: This method must be called before any Room operations
    /// e.g. in the `App.init()` or `AppDelegate/SceneDelegate`
    public static func setTracing(_ tracing: any Tracing) {
        state.mutate { $0.tracing = tracing }
    }

    /// Set a custom logger for the SDK
    /// - Note: This method must be called before any other logging is done
    /// e.g. in the `App.init()` or `AppDelegate/SceneDelegate`
    public static func setLogger(_ logger: any Logger) {
        state.mutate { $0.logger = logger }
    }

    /// Adjust the minimum log level for the default `OSLogger`
    /// - Note: This method must be called before any other logging is done
    /// e.g. in the `App.init()` or `AppDelegate/SceneDelegate`
    public static func setLogLevel(_ level: LogLevel) {
        setLogger(OSLogger(minLevel: level))
    }

    /// Disable logging for the SDK
    /// - Note: This method must be called before any other logging is done
    /// e.g. in the `App.init()` or `AppDelegate/SceneDelegate`
    public static func disableLogging() {
        setLogger(DisabledLogger())
    }

    @available(*, deprecated, renamed: "setLogLevel")
    public static func setLoggerStandardOutput() {
        setLogLevel(.debug)
    }

    /// Notify the SDK to start initializing for faster connection/publishing later on. This is non-blocking.
    public static func prepare() {
        // TODO: Add RTC related initializations
        DeviceManager.prepare()
    }

    /// Sets the bitrate WebRTC's send-side bandwidth estimator should start a published H.264
    /// video track at, via `x-google-start-bitrate` munged into the SFU's SDP answer.
    ///
    /// WebRTC always starts a new send stream at its own hardcoded ~300 kbps default and ramps
    /// up from there, regardless of the publish preset's bitrate ceiling — costing several
    /// seconds of low-bitrate, high-QP video before it climbs to a usable rate. No ObjC API on
    /// this platform exposes a way to override that starting point directly; this is libwebrtc's
    /// own SDP-level hook for it (see `Transport.mungeH264StartBitrate(_:kbps:)`).
    ///
    /// A hint, not a guarantee: the bandwidth estimator still corrects downward within about a
    /// second if the network can't actually sustain it.
    ///
    /// - Note: Applies to every H.264 video track published after this call, not per-track.
    ///   Pass `nil` to stop munging and fall back to WebRTC's own default.
    public static func set(videoPublishStartBitrateKbps kbps: Int?) {
        state.mutate { $0.videoPublishStartBitrateKbps = kbps }
    }

    /// Current value set via ``set(videoPublishStartBitrateKbps:)``. Consulted by
    /// `Room+SignalClientDelegate` when munging the publisher's answer SDP.
    static var videoPublishStartBitrateKbps: Int? { state.read { $0.videoPublishStartBitrateKbps } }
}

// Lazily initialized to the first logger
let sharedLogger = LiveKitSDK.state.logger

// Lazily initialized to the first tracing
let sharedTracing = LiveKitSDK.state.tracing
